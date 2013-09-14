#!/bin/bash
# Copyright 2013 Rob Wu <gwnRob@gmail.com> (https://robwu.nl/)
# Last modified 14 sept 2013
# 
# Environment variables:
# XAR       = Path to patched xar executable
# CERTDIR   = Path to certificates and keys
#
# Requirements: certs/ directory as defined in README.md

if [ $(uname) == 'Darwin' ] ; then
    readlink=greadlink
else
    readlink=readlink
fi
curdir="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )/" && pwd )"
certdir="${curdir}/certs"
xar="${curdir}/xar"

# Allow override through environment variables
[ -n "$XAR" ] && xar="$XAR"
[ -n "$CERTDIR" ] && certdir="$CERTDIR"

if [ ! -x "${xar}" ] ; then
    echo "${xar} is not an executable!"
    exit 10
fi

if [ $# == 0 ] ; then
    echo "Usage: $0 path/to/name.safariextension/"
    exit 1
fi
# Resolve relative paths, get rid of trailing slashes, validate path
safariextensiondir="$( readlink -f "$1" )"

if [ -z "${safariextensiondir}" ] ; then
    echo "Error: Path not found: ${safariextensiondir}"
    exit 2
fi

if [ ! -d "${safariextensiondir}" ] ; then
    echo "Error: Path is not a directory: ${safariextensiondir}"
    exit 3
fi

# Last part of dir, eg. "name.safariextension"
safaridirname="${safariextensiondir##*/}"
# Name of extension, eg "name"
extensionname="${safaridirname%.safariextension}"
# Parent dir of the "name.safariextension" and "name.safariextz", eg. "/resolved/path/to"
safaridistdir="${safariextensiondir%/*}"

if [ "${extensionname}" == "${safaridirname}" ] ; then
    echo "Error: ${safaridirname} does not end with .safariextension!"
    exit 4
fi

# Check if all certificate requirements are satisfied...
if [ ! -d "${certdir}" ] ; then
    echo "Error: Certificate dir not found: ${certdir}"
    exit 5
fi
for cert in cert.der cert01 cert02 key.pem ; do
    if [ ! -f "${certdir}/${cert}" ] ; then
        echo "Error: Not found in certificate dir: ${cert}"
        exit 5
    fi
done

# Size of the signature
sigsizefile="${certdir}/size.txt"
# Create file if not existent
[ ! -e "${sigsizefile}" ] && openssl dgst -sign "${certdir}/key.pem" -binary < "${certdir}/key.pem" | wc -c > "${sigsizefile}"
sigsize="$(cat "${sigsizefile}" )"

extzfile="${safaridistdir}/${extensionname}.safariextz"

# Insert --verbose if you want to see the files being processed
"${xar}" -czf "${extzfile}" \
    --distribution \
    --directory="${safaridistdir}" \
    "${extensionname}.safariextension"

"${xar}" --sign -f "${extzfile}" --digestinfo-to-sign tmp-digest.dat \
    --sig-size "${sigsize}" \
    --cert-loc "${certdir}/cert.der" \
    --cert-loc "${certdir}/cert01" \
    --cert-loc "${certdir}/cert02"

openssl rsautl -sign -inkey "${certdir}/key.pem" -in tmp-digest.dat -out tmp-sig.dat

"${xar}" --inject-sig tmp-sig.dat -f "${extzfile}"

rm -f tmp-sig.dat tmp-digest.dat

echo "Built ${extzfile}"
