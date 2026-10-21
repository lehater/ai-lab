# S1-D — Docker Engine/Compose bootstrap (accepted first slice)

**Status:** limited first slice accepted via [PR #6](https://github.com/lehater/ai-lab/pull/6), owner-tested on `lab-test`. Full S1-D remains open.
Target: Ubuntu 24.04 Desktop/amd64 VMware, after accepted S0/S1.
This module installs Docker Engine, Docker Compose and the **Docker daemon's**
HTTP(S) proxy using S0's existing local Xray. It does not change the Xray
listener or enforce proxy use inside arbitrary containers.

## Operator commands

```bash
make docker-test
make docker-setup
make docker-setup          # safe rerun
make docker-verify
make docker-pull-test      # docker pull + run hello-world
make docker-compose-test   # ephemeral Compose service/default bridge + teardown
```

`docker-setup` installs the official signed Docker APT Noble/amd64
repository after checking the signing key's primary fingerprint
`9DC858229FC7DD38854AE2D88D81803C0EBFCD88`; it installs
`docker-ce`, `docker-ce-cli`, `containerd.io`,
`docker-buildx-plugin`, `docker-compose-plugin` and a separate
`/etc/systemd/system/docker.service.d/ai-lab-proxy.conf`.
It refuses conflicting distro packages and differing existing
Docker repository, key or daemon proxy configuration rather than
overwriting/removing them. It does not add the user to the
root-equivalent `docker` group: use `sudo docker`.

`docker-verify` checks packages, daemon, Compose, systemd proxy settings
and standard Docker API TCP management ports. `docker-pull-test`
runs `sudo docker run --rm --pull=always hello-world`, proving that the
daemon can obtain a registry image and execute a container, **not**
that individual app containers use Xray.

`docker-compose-test` creates one temporary Compose project containing
`hello-world`, checks that the automatically created network uses normal
`bridge` driver with `internal=false`, and removes its containers and
network on exit. It **publishes no ports**, creates no volumes and leaves
no persistent services. This tests Compose execution and its standard
network lifecycle, not egress proxy policy or application networking.

## Default Compose networking and explicit limitations

Use the **ordinary Compose bridge network by default**.
Docker Engine's HTTP_PROXY/HTTPS_PROXY settings are for **dockerd**
(primarily registry access), **not** for all containers.
A normal bridge container on `lab-test` was verified to reach GitHub
directly (HTTP 200). Its explicit attempt to reach the current Xray
at `host.docker.internal:10808` failed because Xray binds only
`127.0.0.1:10808`; do not advertise that address as a working
container proxy or change Xray to `0.0.0.0`.

A workload requiring container-level proxy, restricted egress or isolation
must supply a real use case and receive its **own** network design,
configuration and acceptance tests. The owner deliberately deferred
a universal `--internal` network and systemd proxy forwarder.
No custom bridge proxy is part of this baseline; see
[decision D-011](../../docs/project/decisions.md) and experiment evidence
in [project state](../../docs/project/state.md).

## Safety, reproducibility, and verification

- Docker's default networks are not an egress firewall. Do **not** claim
  forced proxy routing or isolation from direct internet access.
- Do not publish app ports automatically; Docker-managed firewall rules
  can bypass assumptions based on UFW. Treat exposed services and external
  LAN reachability as explicit workload-dependent acceptance concerns.
- Neither the Docker TCP API nor test-container ports are intentionally
  exposed by this candidate. Negative checks on 2375/2376 do **not**
  certify all possible LAN exposure.
- Docker package versions are selected from the moving stable APT
  repository, not pinned. Record versions during acceptance.
- Test scripts preserve existing `daemon.json`, containers, images and
  volumes. They do not implement a destructive uninstall.
- Xray currently starts in the GNOME desktop session; Docker can start
  before desktop login. Registry pulls before proxy startup may fail.
- `make docker-test` is offline syntax/template coverage. It cannot
  certify live setup or a clean-machine replay.

### Observed acceptance on lab-test

Owner reported successful initial and repeat `make docker-setup` for
Docker Engine **29.9.2**, Compose **v5.6.1**, daemon proxy
verification and Docker Hub `hello-world` pull/launch.
Post-reboot `make host-verify`, `make docker-verify` and
`make docker-pull-test` also passed. After experimental networking
tools were removed, `make docker-test` and `make docker-verify` passed
again. Owner then ran the revised `make docker-test` (Compose smoke
contract PASS) and `make docker-compose-test` on `lab-test`:
the temporary `hello-world` Compose service exited 0, its
`bridge/internal=false` network had no published ports, and
both container and network were removed; the test reported
`PASS: Docker Compose default bridge service and cleanup.`
A final local inspection showed no running Docker containers/published
ports and no listeners on Docker API ports 2375/2376, while Xray
remained bound to 127.0.0.1:10808. This does not establish remote
LAN isolation.
These results do **not** establish a fresh S0 → S1 → S1-D replay,
package-version pinning, externally tested LAN security, or container
proxy-routing. Full findings and prior optional network experiments
are preserved in [project state](../../docs/project/state.md).

### Remaining integrated full-chain acceptance

Follow [the complete USB S0 → S1 → S1-D operator replay](../README.md)
from the original `vmware-tools-ready` snapshot or a clone.
It includes the manual first GUI launch and GitHub SSH key registration,
repeated install, post-reboot tests and a privacy-safe evidence summary.
Do not claim full-chain reproducibility before that replay has passed.
A separate LAN-host test is required before claiming LAN isolation.

References:
[Docker Ubuntu installation](https://docs.docker.com/engine/install/ubuntu/),
[daemon proxy configuration](https://docs.docker.com/engine/daemon/proxy/),
[Docker networking](https://docs.docker.com/engine/network/),
[Docker firewall caveats](https://docs.docker.com/engine/network/packet-filtering-firewalls/).
