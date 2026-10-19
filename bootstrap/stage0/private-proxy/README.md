# Private proxy payload — local files only

Copy these exact files from protected storage into **this same directory**:

- `v2rayN-linux-64.deb` — offline v2rayN 7.20.2 amd64 package.
- `v2rayn-data.tar.gz` — backed-up v2rayN user data including SECRET credentials.
- `v2rayn-data.sha256` — checksum from the backed-up archive.

The archive may contain subscription URLs, account keys and other secrets.
**Only this README is committed to GitHub.** The actual payload must never be
committed, uploaded to public storage, or included in support logs.

After copying, run `bash ../bootstrap.sh` as the desktop user on clean
Ubuntu 24.04 in VMware. No parameters or alternative paths are needed.

Encryption of the private payload is deferred until the end-to-end test works.
