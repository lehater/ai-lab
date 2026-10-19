# Stage 0 — Offline USB bootstrap (VMware profile)

**Target now:** Ubuntu 24.04 Desktop amd64, VMware only. Bare metal and other hypervisors are not supported/tested yet. This stage does not need Git or online package access before proxy recovery.

## Three separate objects

1. **Public source in Git**: scripts, docs, builder; versioned in `ai-lab`.
2. **USB program bundle**: `bootstrap.sh`, `install.sh`, `v2rayN-linux-64.deb`, statically runnable `age` executable, `checksums.sha256`. No secrets.
3. **Encrypted secret bundle**: `v2rayn-data.tar.gz.age`, stored outside Git, made by encrypting the existing private tarball with age passphrase or recipient key. The recovery passphrase/private key must be available independently.

The separate archive is never copied to the code bundle by `package.sh`. Do not check secrets, private SSH identities, original proxy tarballs or passphrases into Git.

## Build on a trusted workstation

Install a trusted, independently verified Linux amd64 `age` binary on the build machine (it must be executable on Ubuntu 24.04 without needing additional online packages). This is a **build-time input**; this repository intentionally does not download or embed unverified executables.

Example passphrase encryption (interactive password entry):

```bash
age -p -o ~/v2rayn-data.tar.gz.age ~/proxy-migration/v2rayn-data.tar.gz
bash bootstrap/stage0/package.sh ~/proxy-migration /path/to/trusted/age ~/stage0-usb
```

Keep `~/v2rayn-data.tar.gz.age` separate from the source repo; copy the executable bundle and encrypted archive to removable media as needed. Test decryption with the same `age` executable prior to wiping original recovery data. The earlier `package-test.sh` is obsolete and intentionally no longer used.

## Run on clean VMware Ubuntu

```bash
bash /media/.../stage0-usb/bootstrap.sh /media/.../v2rayn-data.tar.gz.age
```

Stage 0 checks Ubuntu and bundled file hashes, decrypts archive in a temporary private directory, invokes existing offline proxy installer, configures GNOME autostart, waits for operator to launch v2rayN GUI, verifies GitHub via explicit local proxy, configures APT proxy, installs Git, curl, OpenSSH client, CA certs and VMware tools, then clones the public repo via proxied HTTPS.

No GitHub SSH key is needed to clone this public repo. SSH identity for *pushes* is a subsequent host setup step; the user must authorize adding a newly generated public key to their GitHub account.

## Limitations before acceptance

- Fresh-VM execution **not yet tested**; do not merge until validated.
- GUI application must be launched after login; GNOME autostart applies on later logins.
- No Docker exposure, firewall, native Ubuntu or other hypervisor support in Stage 0.
- Checksums in the same USB directory detect accidental changes, **not** malicious tampering. Verify trusted release digests or signed manifest out of band.
- `age` supports both passphrase-based and identity-based decryption; avoid losing credentials.
- Existing installer needs further hardening against malicious tar entries; use only the trusted private archive prepared by the user.
- Current stage decrypts to local temporary disk and erases temporary files on normal exit; this is not a forensic secure deletion guarantee. Avoid untrusted multi-user hosts.
- VMware tools are installed only after APT connectivity, **not** prerequisites for proxy recovery.

## Acceptance checks

Clean Ubuntu 24.04 VMware snapshot → run Stage 0 from USB only → manually launch v2rayN → proxied GitHub check → APT install and open-vm-tools-desktop → Git HTTPS clone. Repeat without overwriting existing configuration. Verify all operations use the proxy; direct outbound access may be disabled during the test.
