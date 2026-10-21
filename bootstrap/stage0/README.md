# Stage 0 — Offline Bootstrap (Ubuntu 24.04 Desktop, VMware)

**Начало установки и полный порядок S0 → S1:** [README на USB](../README.md).
Этот файл описывает только детали S0. При копировании всего `bootstrap/` на
флешку основной маршрут будет в `USB/bootstrap/README.md`.

**The folder structure in GitHub and on USB is identical.** Download or copy
`bootstrap/` to a USB stick without moving or renaming directories.

```text
bootstrap/
├── README.md                         # USB start here: S0 → S1
├── host/                             # S1 scripts and instructions
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

**Limitations:** Unencrypted private archive (protect physical access to
USB); manual first launch in GNOME; Ubuntu 24.04 Desktop / VMware only.
Autostart after reboot on `lab-test` was subsequently confirmed by the owner
following a clean `vmware-tools-ready` snapshot replay (proposed evidence in
[PR #5](https://github.com/lehater/ai-lab/pull/5)); the first GUI launch
remains manual.
Later stages handle SSH key registration, Docker, firewall and hardening.
Never commit `private-proxy` payloads.

**MVP validation:** USB installation from a clean `lab-test` VMware
snapshot passed twice: offline v2rayN install, HTTP and SOCKS5 proxy,
APT package installation, Git and public repository clone.
