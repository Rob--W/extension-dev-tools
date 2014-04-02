# (c) 2013 Rob Wu <gwnRob@gmail.com>
# Exports several functions to ease Chrome extension development
#
# crx - Bootstraps Chrome extension if not existent
# crxshow - Show whether profile directory for current instance exists.
# crxtest - Starts Chrome, loading the Chrome extension from current path or parent
# crxdel - Deletes temporary profile
#
# Global variables
# __CRX_CHROMIUM_BIN        - Name of Chromium executable
# __CRX_EXTRA_EXTENSIONS    - Comma-separated list of extensions to be loaded
# __CRX_PROFILE             - Path to temp profile dir
# __CRX_PWD                 - Path to extension dir
# 


# If chromium is not found within the path, but google-chrome is, use it.
__CRX_CHROMIUM_BIN=chromium
if ! type "chromium" >/dev/null 2>/dev/null; then
    if ! type "google-chrome" >/dev/null 2>/dev/null; then
        __CRX_CHROMIUM_BIN=google-chrome
    fi
fi

# Chrome extension that provides quick access to chrome://extensions/
__CRX_EXTRA_EXTENSIONS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/launch-chrome-extensions-on-startup"

crx() {
    if [ $# -ne 0 ] ; then
        if [ -e "$@" ] ; then
            if [ ! -e "$@/manifest.json" ] ; then
                echo "$@ already exists. Did not create crx files."
                return
            else
                echo "$@/manifest.json already found."
            fi  
        else
            if [ "$@" == ${PWD##*/} ] ; then
                echo "Did not create directory or crx files, because the current directory has the same name"
                return
            fi
            echo "Created directory $@"
            mkdir "$@"
        fi
        echo "Changed directory to $@"
        cd "$@"
    fi
    if [ -e manifest.json ] ; then
        echo "manifest.json already found"
    else
        echo '{
    "name": "Name ",
    "version": "1",
    "manifest_version": 2,
    "background": {
        "scripts": ["background.js"],
        "persistent": true
    },
    "content_scripts": [{
        "run_at": "document_idle",
        "js": ["contentscript.js"],
        "matches": ["<all_urls>"]
    }],
    "browser_action": {
        "default_title": ""
    },
    "permissions": [
        "tabs",
        "<all_urls>"
    ],
    "web_accessible_resources": [
    ]
}' > manifest.json
        touch background.js
        touch contentscript.js
        echo "Created manifest.json, background.js and contentscript.js"
    fi
    __CRX_PWD=${PWD}
}
__get_crx_profile_path() {
    if [ ! -d "${__CRX_PWD}" ] ; then
        local path=${PWD}
        while [[ -n "${path}" && ! -e "${path}/manifest.json" ]] ; do
            path=${path%/*}
        done
        if [ -z "${path}" ] ; then
            echo "manifest.json not found in current or parent directory!"
            return 1
        fi
        __CRX_PWD=${path}
    fi
    if [ -z "${__CRX_PROFILE}" ] ; then
        # /tmp/CRX.prof-ABCDEF-BASENAMENOSPACE
        __CRX_PROFILE=/tmp/CRX.prof-$(echo "${__CRX_PWD}" | md5sum | cut -c 1-6 )-$(basename "${__CRX_PWD// /}")
    fi
}
crxshow() {
    __get_crx_profile_path || return
    if [ -e "${__CRX_PROFILE}" ] ; then
        # Show command for launching Chrome manually
        echo "${__CRX_CHROMIUM_BIN} --user-data-dir=${__CRX_PROFILE}"
    else
        echo "${__CRX_PROFILE} not found"
    fi
}
crxtest() {
    __get_crx_profile_path || return
    local command="cd \"${__CRX_PWD}\" && ${__CRX_CHROMIUM_BIN} --user-data-dir=\"${__CRX_PROFILE}\" \
--load-extension=\"${__CRX_EXTRA_EXTENSIONS},.\" $@"
    echo "( ${command} )"
    bash -c "${command}"
}
crxdel() {
    __get_crx_profile_path
    if [[ -d "${__CRX_PROFILE}" ]] ; then
        if [[ "${__CRX_PROFILE}" =~ "/tmp/" ]] ; then
            rm -r "${__CRX_PROFILE}" && echo "# Removed \"${__CRX_PROFILE}\""
        else
            echo "# Run the following command"
            echo "# rm -r ${__CRX_PROFILE}"
        fi
    else
        echo "# \$__CRX_PROFILE is not a directory"
    fi
    __CRX_PWD=
    __CRX_PROFILE=
}
