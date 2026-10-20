# Stage 0 — Offline Bootstrap (Ubuntu 24.04 Desktop, VMware)

**The folder structure in GitHub and on USB is identical.** Download or copy
`bootstrap/` to a USB stick without moving or renaming directories.

```text
bootstrap/
└── stage0/
    ├── bootstrap.sh
    ├── README.md
    ├── proxy/
    │   ├── install.sh
    │   ├── configure.sh
    │   ├── verify.sh
    │   └── README.md
    └── private-proxy/
        ├── README.md                   # this placeholder is in Git
        ├── v2rayN-linux-64.deb         # add locally (NOT in Git)
        ├── v2rayn-data.tar.gz          # add locally (SECRET; NOT in Git)
        └── v2rayn-data.sha256          # add locally (NOT in Git)
```

## Prepare the USB

1. Download the GitHub `bootstrap/` directory from the approved revision.
2. From protected offline storage copy the three files listed in
   `stage0/private-proxy/README.md` directly to
   `USB/bootstrap/stage0/private-proxy/`.
3. Nothing needs to be packaged, renamed, decrypted or moved to another path.

## Run on clean Ubuntu

```bash
bash /media/USER/USB/bootstrap/stage0/bootstrap.sh
```

No command arguments required. Stage 0 installs offline v2rayN from
`private-proxy/`, restores the user configuration, sets GNOME autostart,
prompts the operator to start v2rayN manually in GNOME and activate a server, then checks
GitHub via HTTP proxy, configures APT, installs Git, curl, SSH client and
VMware Tools, verifies HTTP/SOCKS5, then clones the public repository via
proxied HTTPS. Initial public clone does **not** require an SSH key.

**Limitations:** unencrypted private archive (protect physical access to USB);
manual first launch in graphical session; Ubuntu 24.04 Desktop / VMware only.\n\n**MVP validation:** USB deployment from a clean `lab-test` VMware snapshot passed twice: v2rayN installation, proxy HTTP/SOCKS5 verification, APT, Git and repository clone. Autostart after a subsequent GNOME login has not yet been independently confirmed. Later stages handle SSH key registration, Docker, firewall and
hardening. Never commit `private-proxy` payloads.
