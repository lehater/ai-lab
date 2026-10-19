# Proxy Bootstrap

Bootstrap for v2rayN 7.20.2 on Ubuntu 24.04 LTS.

## Components

- install.sh: offline DEB installation and configuration restore
- verify.sh: package, HTTP and SOCKS5 verification

## Current status

- verify.sh: PASS on VMware Ubuntu
- install.sh: NOT YET TESTED end-to-end
- GNOME/APT/Bash integration: manual
- Autostart and firewall: manual
- Encrypted backup: NOT IMPLEMENTED

## Security

The configuration archive contains sensitive credentials.
Never commit archives, subscription URLs, private keys or secrets.

## Verification

Run on a machine with v2rayN and Xray already running:

    ./bootstrap/proxy/verify.sh
