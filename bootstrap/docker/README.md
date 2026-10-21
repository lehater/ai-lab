# S1-D — Docker Engine/Compose + proxy for dockerd (first candidate)

**Status:** [draft PR #6](https://github.com/lehater/ai-lab/pull/6), proposal; not accepted in `main`. This is the **host daemon/registry
slice only**, not the whole S1-D milestone. Run it on `lab-test` after
accepted S0 + S1; do not run on a production host or the manually
configured reference `lab`.

## Operator commands

From the PR branch on Ubuntu 24.04 Desktop/amd64:

```bash
make docker-test
make docker-setup
make docker-setup           # rerun / idempotence
make docker-verify
make docker-pull-test       # docker pull + run hello-world
make docker-net-diagnose    # bridge network diagnostics (no host network edits)
make docker-internal-probe   # temporary isolated bridge; direct HTTPS denied?
make docker-forwarder-probe  # transient bridge-only systemd proxy (test VM only)
```

`docker-setup` invokes `bootstrap/docker/setup.sh`. It uses S0's
proxied APT and the existing GitHub HTTPS proxy check from S1. It adds
Docker's **official signed APT repository** (Noble/amd64) and installs
`docker-ce`, `docker-ce-cli`, `containerd.io`,
`docker-buildx-plugin` and `docker-compose-plugin`.

Before trusting the repository it downloads the official signing key
through S0's proxy and checks its primary GPG fingerprint against
`9DC858229FC7DD38854AE2D88D81803C0EBFCD88`. It refuses to overwrite
an unknown Docker key, APT source or `ai-lab-proxy.conf` file and stops on
known conflicting distro packages instead of deleting them.

The daemon receives HTTP_PROXY/HTTPS_PROXY for
`http://127.0.0.1:10808` through an isolated systemd unit drop-in at
`/etc/systemd/system/docker.service.d/ai-lab-proxy.conf`; S0 is still
responsible for launching the proxy. Proxy must be running during image
pulls. Docker daemon may start before GNOME login, but image pulls depend
on the later user-session Xray availability.

`docker-verify` checks installed package status, daemon liveness,
systemd proxy environment, Compose version and standard Docker TCP
management port absence. `docker-pull-test` additionally runs
`sudo docker run --rm --pull=always hello-world`. **This verifies the
daemon registry pull and process startup, not outbound networking from
a Docker bridge container.**

## Next diagnostic: host Xray proxy versus Docker bridge

After post-reboot `docker-verify` and `docker-pull-test` pass, run
`make docker-test` (updated offline syntax check), then
`make docker-net-diagnose`. This diagnostic does **not** modify proxy
listeners, the Docker network, daemon config or host firewall. It does
download/cache the `curlimages/curl:8.16.0` test image and creates two
**ephemeral** containers with `--network bridge`, no published ports,
no added capabilities and no-new-privileges.

It prints the existing host TCP listener for 10808 and the default
Docker bridge gateway; then tests HTTPS from the bridge container both
through `host.docker.internal:10808` (using the Docker
`--add-host host.docker.internal:host-gateway` mapping) and with direct
outbound access, bypassing proxy settings.

A running Xray bound only to `127.0.0.1` **cannot normally be reached**
via the host bridge gateway IP. That test failure is diagnostic evidence,
**not proof that Docker itself is broken**. A successful direct test
means traffic can bypass Xray; it does not establish acceptable routing
or firewall isolation. Keep results distinct; do not change v2rayN to
`0.0.0.0` or open ports simply to make the test pass.

To determine LAN isolation, a separate, controlled test from another
machine on the LAN will be required. Loopback socket checks alone
cannot prove that Docker port publishing or other rules never expose
services. No external LAN test is performed by this diagnostic.

## Controlled second experiment — Docker internal-only network

The first bridge test on `lab-test` gave these **observed** results:

- Xray listens on `127.0.0.1:10808`; the default Docker bridge gateway
  is `172.17.0.1`.
- Container proxy request via `host.docker.internal:10808` failed
  (HTTP 000, curl exit 7).
- Container **direct** HTTPS to GitHub succeeded (HTTP 200).

As a next **experimental** check, run `make docker-internal-probe`.
It creates a new, uniquely named **temporary Docker bridge with
`--internal`**, verifies Docker reports `Internal=true`, and attempts
direct HTTPS to GitHub with all proxy use disabled. The temporary bridge
and its **Docker-managed firewall rules** are removed by an EXIT trap.
The script downloads `curlimages/curl:8.16.0` via the daemon only when
not already cached; no images or containers are published. If cleanup
fails, it reports the exact network ID for operator cleanup.

**This is not read-only:** Docker temporarily creates a network/interface
and firewall rules during this test. It does **not** change the host Xray
listener, host firewall policy, systemd units or Docker daemon configuration.
A failed direct HTTPS probe supports this specific isolation observation,
but does **not alone prove all egress paths are blocked** or LAN safety.

According to [Docker's `--internal` contract](https://docs.docker.com/reference/cli/docker/network/create/),
containers on internal networks do not have a default external route,
while the host gateway remains reachable. The **candidate next design**:

1. Create a dedicated, versioned internal Docker network with a
   controlled subnet and stable bridge interface, avoiding collisions.
2. Expose a small **local TCP forwarder only on that bridge interface**
   (for example, systemd socket with `BindToDevice` and
   `systemd-socket-proxyd`) forwarding traffic to existing
   `127.0.0.1:10808`. Never bind Xray itself to `0.0.0.0`.
3. Explicitly configure app/container `HTTP_PROXY` and `HTTPS_PROXY`
   to the dedicated bridge-gateway listener, not to the unreachable
   loopback socket.
4. Independently test positive proxied HTTPS, negative **direct**
   egress, service unavailability when Xray stops, host listener scope,
   and LAN access from another device. Reboot and rerun. Do not claim
   security from a single negative curl or from Docker `--internal`
   alone.

Do not install a permanent forwarder or alter firewall rules until the
internal network test and the security model have been reviewed.

## Controlled third experiment — bridge-only forwarder (NOT installed)

The `make docker-internal-probe` test **passed on `lab-test`** with
a temporary `--internal` bridge, gateway `172.18.0.1`, and clean
network teardown. The observed direct HTTPS failure was specifically
a **DNS resolution timeout** and did not independently prove that
connections to pre-resolved public IPs were blocked.

The next `make docker-forwarder-probe` test creates **another temporary**
internal bridge and, only while the test runs, uses the **standard**
`systemd-socket-proxyd` to forward a socket on that bridge gateway's
TCP port **11080** to the existing Xray loopback listener
`127.0.0.1:10808`. The systemd socket has `BindToDevice` pointing to
the temporary bridge interface, so packets arriving on other host
interfaces must not be accepted by it. The proxy process runs as the
unprivileged `nobody` user.

Before creating the new network, the test checks that the **same
literal public IP is reachable over direct HTTPS from the existing
non-internal default bridge**. If that positive control fails, the
experiment stops as inconclusive without creating a network or socket.
Then it verifies actual container HTTPS via the bridge-scoped listener
and attempts direct HTTPS to that literal IP (`1.1.1.1`)
**without DNS resolution**, addressing the previous DNS-only
false assurance. Temporary units live under `/run/systemd/system/`;
the exit handler stops and removes those units, reloads systemd and
removes the temporary Docker network. A cleanup failure is reported
as an error, with the network identifier.

**This is a privileged network experiment**, not a read-only diagnostic:
during the run it installs a temporary host TCP listener on the new
bridge, alters Docker-managed temporary networking/firewall rules and
may briefly allow other containers attached to the same bridge to use
the proxy. It leaves the Xray bind address, persistent systemd config,
Docker daemon config and UFW policy unchanged. Only run it on
`lab-test` with a recoverable snapshot; do not run on production or
an untrusted LAN.

Even a positive proxied HTTPS + negative direct-IP result is **not proof
of comprehensive egress or LAN isolation**. A separate test from another
LAN host, reboot/cleanup checks, IPv6 and routing assessment are needed
before creating a permanent module. Do **not** enable the temporary
units at boot.

References: [systemd `BindToDevice=`](https://www.freedesktop.org/software/systemd/man/latest/systemd.socket.html),
[`systemd-socket-proxyd`](https://www.freedesktop.org/software/systemd/man/257/systemd-socket-proxyd.html),
[Docker internal network](https://docs.docker.com/reference/cli/docker/network/create/).

## Security boundaries

- `sudo docker` only; do not add desktop users to the `docker` group
  automatically — the group grants root-level host access.
- No Docker TCP API listener is enabled by these scripts. No container
  ports are published by the acceptance test.
- Docker may modify iptables and published container ports can bypass
  UFW firewall expectations. **LAN isolation is NOT established by this
  candidate**, even if `docker-pull-test` passes.
- The repository uses latest packages available from the stable APT repo
  at install time, **not pinned versions**. Record installed versions in
  test evidence; repeatability of a specific package build remains a gap.
- No daemon configuration (`daemon.json`) or existing containers, images
  and volumes are deleted. A preexisting daemon proxy setting triggers
  refusal for manual review; no automatic takeover.
- `docker-test` is a syntax/template test. It does not invoke privileged
  operations, Docker daemon or network; the live installation and post-reboot daemon/image pull checks have
  passed on `lab-test`, but bridge HTTPS and LAN security remain unverified.

## Acceptance on lab-test (before a merge)

1. Confirm no manually installed Docker or conflicting packages.
2. Check out PR branch through S0 HTTPS proxy; run `make docker-test`.
3. Run `make docker-setup` twice; both runs should succeed without
   overwriting local settings. Run `make docker-verify`.
4. Run `make docker-pull-test` while v2rayN/Xray is up.
5. Reboot, do not start v2rayN manually, and repeat `make docker-verify`
   and `make docker-pull-test`.
6. Report `docker version`, `docker compose version`, the two PASS
   lines, installation errors and any limitations. The next S1-D slice
   must test bridge-container HTTP(S) through a controlled route and
   negative LAN access before claiming complete S1-D.

Reference: [Docker Ubuntu APT installation](https://docs.docker.com/engine/install/ubuntu/),
[Docker daemon proxy](https://docs.docker.com/engine/daemon/proxy/),
[Docker postinstall security](https://docs.docker.com/engine/install/linux-postinstall/).
