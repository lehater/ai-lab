# Stage 0 — VMware USB bootstrap (initial test version)

Target: **Ubuntu 24.04 Desktop amd64, VMware**. Stage 0 is runnable offline before Git/apt networking is configured.

## Separation

- **GitHub:** source code for `bootstrap/stage0`, `bootstrap/proxy` and `bootstrap/host`. No secret settings.
- **USB program bundle:** `bootstrap.sh`, `install.sh`, `configure.sh`, `v2rayN-linux-64.deb`, `checksums.sha256`.
- **Private local directory:** `v2rayn-data.tar.gz` and `v2rayn-data.sha256`. These files contain **real credentials and proxy profiles**. Keep on trusted removable media, never commit, publish or synchronize to public storage.

## Package

From the cloned repo on an already-working machine:

```bash
bash bootstrap/stage0/package.sh ~/proxy-migration ~/stage0-usb
```

The USB program bundle contains no proxy configuration. Copy the private configuration separately to a second directory on the removable drive, for example `private-proxy/`.

## Run on a clean VMware Ubuntu Desktop

```bash
bash /media/.../stage0-usb/bootstrap.sh /media/.../private-proxy
```

Stage 0 verifies the public program bundle, verifies the private archive, installs v2rayN and restores its configuration, installs GNOME autostart through `configure.sh`, waits for the user to launch the GUI and select a server, confirms HTTPS through the proxy, configures APT, installs Git/curl/OpenSSH client and VMware Tools, and clones the public repo through HTTPS using an explicit Git proxy.

The private archive is copied into a restricted temporary directory because the existing offline `install.sh` expects the archive, checksum and DEB to be colocated. Stage 0 does not upload any private material to GitHub.

## Deliberate omissions and limitations

- Encryption/hardening is **deferred** until the end-to-end flow works. Anyone who obtains the private archive may gain access to its credentials.
- No automatic GitHub SSH registration; a public clone does not require it.
- GUI launch requires a logged-in desktop; autostart applies on later logins.
- No support for bare metal or other hypervisors yet.
- USB SHA256 file validates internal consistency only. Build and distribute from a trusted workstation.
- VMware Tools are installed after proxy APT networking works.
- Existing archive installer requires trusted private tar files; hardening archive extraction is pending.
- Must be tested with a clean VMware Ubuntu snapshot before merge.
