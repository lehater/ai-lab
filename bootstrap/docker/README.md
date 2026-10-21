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
