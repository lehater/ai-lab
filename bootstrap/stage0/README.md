# Stage 0: offline-to-GitHub bootstrap

## Goal

Take a **clean Ubuntu 24.04 Desktop amd64** machine with no direct external
internet access to a working v2rayN proxy, configured APT, installed Git,
and a checked-out public `lehater/ai-lab` repository.

This is a **host/desktop** bootstrap, not a Docker service. It runs as the
intended desktop user, never with `sudo bash`.

## Trust and files

Stage 0 is distributed on removable or offline storage and must contain:

```text
offline-proxy/
├── bootstrap.sh            # this directory's stage0 script
├── install.sh              # existing bootstrap/proxy/install.sh
├── v2rayN-linux-64.deb     # v2rayN 7.20.2 amd64
├── v2rayn-data.tar.gz      # private user configuration (SENSITIVE)
└── v2rayn-data.sha256
```

The existing installer checks the archive hash and package name/version.
**This is an unencrypted, temporary test format**, not a suitable permanent
backup. Keep it offline and access-restricted; do not commit it or copy it to
public shares. The hash is an integrity check, not proof of authenticity.

Before production use we must build an encrypted distribution and verify the
installer DEB digest against a trusted published digest. The decryptor and
needed dependencies must themselves be available offline.

## Run

1. Install Ubuntu Desktop and log into GNOME as the target user.
2. Copy the offline bundle to the host.
3. Run `bash /path/to/offline-proxy/bootstrap.sh /path/to/offline-proxy`.
4. After installation, start v2rayN from GNOME, select the server, then press
   Enter in the terminal.
5. Stage 0 checks GitHub via HTTP proxy, configures APT proxy, installs
   `git openssh-client curl ca-certificates`, and clones the public repository
   via HTTPS using an explicit Git proxy.

Override target clone path if required with `AI_LAB_DEST=/path/to/ai-lab`.

## Deliberate boundaries

- Public GitHub clone **does not require an SSH key**. Authentication for
  pushes is a later, separate bootstrap task. Verify GitHub SSH host
  fingerprints against GitHub documentation before trusting them.
- v2rayN is started in a graphical user session; autostart applies on next
  GNOME login. Stage 0 does not claim headless/start-before-login networking.
- Docker, LAN isolation firewall, interactive Bash proxy functions, GNOME-wide
  proxy policy, and VMware Tools belong to subsequent host bootstrap stages.
- APT must have connectivity to Ubuntu mirrors through the proxy.
- `bootstrap.sh` is re-runnable on an already working environment but does not
  overwrite existing v2rayN user configuration or an existing clone.
- Secrets remain outside Git at all times.

## Acceptance criteria

On a fresh test VM: offline package installation succeeds; Xray can be
started; GitHub is reachable through the local proxy; APT installs Git;
the public repository is cloned successfully. Verify startup and service
security separately in later stages.
