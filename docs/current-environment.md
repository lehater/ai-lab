# Observed development environment — lab VM

This describes the **previously configured `lab` development VM** and
manual observations. It is **not evidence** that Host Bootstrap or Docker
Bootstrap can yet reproduce these settings from clean Ubuntu. See
[project state](project/state.md) for tested Stage 0 and remaining work.

## Host

- Ubuntu 24.04.5 LTS Desktop
- VMware Workstation
- 8 vCPU
- 16 GB RAM
- 150 GB ext4 virtual disk

## Proxy

- v2rayN 7.20.2
- Xray mixed HTTP/SOCKS proxy
- Port: 10808
- Docker access: host.docker.internal:10808
- LAN access blocked by host firewall

## Docker

- Docker Engine 29.9.1
- Docker Compose v5.6.0
- Docker daemon uses Xray HTTP proxy

## Verified

- Offline v2rayN installation
- Configuration restore
- Proxy autostart after reboot
- APT package installation
- GitHub HTTPS access
- GitHub SSH authentication
- Docker Hub image pull
- Docker bridge container access through Xray
- LAN proxy isolation
