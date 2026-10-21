#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    sources)
        cat <<'SOURCES'
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: noble
Components: stable
Architectures: amd64
Signed-By: /etc/apt/keyrings/docker.asc
SOURCES
        ;;
    daemon-proxy)
        cat <<'PROXY'
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:10808" "HTTPS_PROXY=http://127.0.0.1:10808" "NO_PROXY=localhost,127.0.0.1,::1"
PROXY
        ;;
    *) echo 'Usage: render.sh {sources|daemon-proxy}' >&2; exit 2 ;;
esac
