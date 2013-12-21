## build-firefox-extension.sh
`build-firefox-extension.sh` is an enhanced version of "cfx xpi". It does the following:

1. Runs `cfx xpi` to pack the extension.
2. If the current directory contains `install.rdf`, `minVersion` and `maxVersion`
   are copied to the "install.rdf" file inside the XPI, and the original install.rdf
   is replaced with this new install.rdf inside the XPI file
   (the previous one is moved to `install.rdf.bak`).
3. If an environment variable "`XPIPEM`" is set, the XPI file is signed using the file
   defined in this environment variable.

The PEM file should contain the following files:

- Your private key.
- Your certificate.
- All other certificates in the certificate chain, up to the root certificate.
  The root certificate is optional, it will not be included in the final xpi file,
  because it should already be included by default in the browser.

For more information, see

- [Signing Firefox extensions with Python and M2Crypto]
  (https://adblockplus.org/blog/signing-firefox-extensions-with-python-and-m2crypto) (blog post by Wladimir Palant).
- [Signing Firefox add ons with a StartSSL Object Code Signing certificate]
  (https://github.com/nmaier/xpisign.py/wiki/Signing-Firefox-add-ons-with-a-StartSSL-Object-Code-Signing-certificate)
  (wiki of xpisign.py)

### Example
```
XPIPEM=codesigning.pem build-firefox-extension.sh
```

### Dependencies
- [Add-on SDK](https://addons.mozilla.org/en-US/developers/docs/sdk/latest/dev-guide/tutorials/installation.html)
  to package the add-on (using the [`cfx tool`](https://addons.mozilla.org/en-US/developers/docs/sdk/latest/dev-guide/cfx-tool.html)).
- [7-zip](http://www.7-zip.org) for manipulating `install.rdf` (at step 2).
- [xpisign](https://github.com/nmaier/xpisign.py/) to sign the XPI file.

### External links
Much of this build script would be obsolete when the following bugs get fixed:

- [Bug 884924 - package.json should support minVersion in targetApplication](https://bugzilla.mozilla.org/show_bug.cgi?id=884924)
- [Bug 657494 - add XPI code-signing tools to 'cfx xpi --sign'](https://bugzilla.mozilla.org/show_bug.cgi?id=657494)
