# Private proxy payload (local only)

This directory is the **only** place for local v2rayN installation files and
configuration used by Stage 0. In GitHub it contains only this README;
`.gitignore` excludes all other files in this directory.

## Required files

```text
bootstrap/stage0/private-proxy/
├── README.md
├── v2rayN-linux-64.deb
├── v2rayn-data.tar.gz
└── v2rayn-data.sha256
```

- `v2rayN-linux-64.deb`: offline installer for **v2rayN 7.20.2 amd64**.
- `v2rayn-data.tar.gz`: complete user data directory from a **working**
  Linux v2rayN, including private profiles/subscriptions and local cores.
- `v2rayn-data.sha256`: SHA-256 checksum of the archive.

## A. Reuse an existing backup (fastest)

On the trusted machine where `~/proxy-migration/` already contains the three
files, check out the desired Git branch and run from the repository root:

```bash
cd ~/projects/ai-lab
cp ~/proxy-migration/v2rayN-linux-64.deb \
   ~/proxy-migration/v2rayn-data.tar.gz \
   ~/proxy-migration/v2rayn-data.sha256 \
   bootstrap/stage0/private-proxy/
```

The original checksum file may name an absolute source path. Stage 0 checks
its SHA-256 digest against the archive in this directory, regardless of the
original path.

## B. Create a new configuration backup

Run these steps on a **trusted Ubuntu machine with a configured, working
v2rayN 7.20.2**. Before archiving, **quit v2rayN completely in the GUI** so
its database is not being modified during backup.

From the repository root:

```bash
(
set -e
cd ~/projects/ai-lab
PRIVATE="$PWD/bootstrap/stage0/private-proxy"
test -d "$HOME/.local/share/v2rayN" || { echo "No v2rayN data"; exit 1; }
mkdir -p "$PRIVATE"
chmod 700 "$PRIVATE"

tar -czf "$PRIVATE/v2rayn-data.tar.gz" \
  -C "$HOME/.local/share" v2rayN

(cd "$PRIVATE" && sha256sum v2rayn-data.tar.gz > v2rayn-data.sha256)

# Use the exact offline DEB already saved on the trusted host.
cp ~/proxy-migration/v2rayN-linux-64.deb "$PRIVATE/"
chmod 600 "$PRIVATE/v2rayn-data.tar.gz" "$PRIVATE/v2rayn-data.sha256"
)
```

If the saved installer does not exist, obtain the **official matching Linux
amd64 v2rayN 7.20.2 DEB** from a trusted source, verify its provenance, and
place it under the exact name `v2rayN-linux-64.deb` in this directory.
Do not substitute a different package version without updating and testing
the installation script.

## C. Verify before copying to USB

```bash
cd ~/projects/ai-lab/bootstrap/stage0/private-proxy
sha256sum -c v2rayn-data.sha256
dpkg-deb -f v2rayN-linux-64.deb Package Version Architecture
tar -tzf v2rayn-data.tar.gz | sed -n '1,12p'
```

Expect `v2rayn-data.tar.gz: OK`, package `v2rayn` version `7.20.2`,
architecture `amd64`, and archive entries beginning with `v2rayN/`.
If using an older checksum file with an absolute path, regenerate it with
`sha256sum v2rayn-data.tar.gz > v2rayn-data.sha256` in this directory.

## D. USB and first run

Copy the **same** `bootstrap/` tree from the Git checkout to USB, including
the local files above. Keep all directory names unchanged.

On a clean Ubuntu 24.04 Desktop VMware machine, from the USB root run:

```bash
bash bootstrap/stage0/bootstrap.sh
```

The script installs v2rayN offline, restores the configuration, configures
GNOME autostart, and prompts for first manual GUI launch before setting up
APT and Git.

## Security boundary

The archive **contains secrets** (subscription URLs, credentials and proxy
configuration). Never commit or upload it, include it in logs, or distribute
the populated `private-proxy/` directory publicly. An unencrypted USB can
be read by anyone with access to it; file permissions on FAT/exFAT media do
not reliably protect its contents. Encryption/hardening is intentionally
deferred until the MVP works. Retain the original protected backup.
