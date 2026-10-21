# Project state — AI Lab

**Updated:** 2026-10-21.  
**Authority:** accepted repository state is what has been merged into `main`;
this file is its human-readable status and handoff index.
It is **not** a substitute for code, tests, or evidence.

## Delivery status

**Long-term target, NOT a verified status:** Enterprise-grade, scenario-independent research infrastructure with repeatable IaC deployment, reusable modules/templates, appropriate security, observability and recovery. The checks below establish only their specific limited scope; Stage 0 still includes a documented manual operator step.

| Area | Status | Evidence / qualification |
| --- | --- | --- |
| S0: offline bootstrap, Ubuntu 24.04 Desktop / VMware | **VERIFIED MVP** | USB → offline v2rayN 7.20.2 install and configuration restore → HTTP/SOCKS5 proxy → APT → Git → public GitHub clone; owner repeated full clean-`lab-test` flow twice. [Merged PR #1](https://github.com/lehater/ai-lab/pull/1). |
| S0: subsequent-login GNOME autostart | **OWNER-VERIFIED ON `lab-test`** | After restoring `vmware-tools-ready` and repeating S0 → S1, owner explicitly confirmed v2rayN started without manual intervention after reboot; proxied HTTPS and authenticated Git SSH passed. Owner-reported verification recorded in [PR #5](https://github.com/lehater/ai-lab/pull/5). |
| S0: encryption and installer hardening | **DEFERRED** | Private proxy data is deliberately unencrypted for this functional MVP; physically protect storage; secrets stay out of Git. |
| S1: reproducible host bootstrap | **IN PROGRESS; FIRST SSH SLICE ACCEPTED ([PR #5](https://github.com/lehater/ai-lab/pull/5))** | After a clean VMware snapshot revert, owner confirmed successful S0 → S1 progression, rerunnable SSH config, GitHub SSH authentication, mocked tests and post-reboot Make checks. Detailed installation transcript not supplied; full S1 host provisioning remains outside this first slice. |
| Docker/Compose bootstrap | **S1-D FIRST SLICE PROPOSED ([DRAFT PR #6](https://github.com/lehater/ai-lab/pull/6)), NOT VERIFIED** | Candidate scripts install official Docker Engine/Compose via signed APT repo and configure host daemon HTTP(S) proxy; offline syntax/template checks only until on-VM evidence is supplied. Bridge container routing and LAN isolation remain outside this first slice. Docker on manually configured `lab` is not clean-VM evidence. |
| AI platform / model runtime | **NOT STARTED AS REPRODUCIBLE DEPLOYMENT** | No platform deployment code is present in `main` at this checkpoint. |
| Applications / experiments | **NOT STARTED IN THIS REPOSITORY** | No runnable end-to-end AI application committed yet. |

## First S1 GitHub SSH slice — owner-reported validation (accepted via PR #5)

Owner-reported console evidence on `lab-test`, 2026-10-21, for [PR #5](https://github.com/lehater/ai-lab/pull/5):

- Fetched `feat/s1-host-ssh-transport` through S0 HTTP proxy; checked out branch.
- Ran `bash bootstrap/host/bootstrap.sh` twice: first created `~/.config/ai-lab/github-ssh.conf`, second reported existing configuration already matched. Each run reported `S1 local config and proxied HTTPS: PASS`.
- Registered a newly created SSH public key in GitHub via owner action; ran `ssh -F ~/.config/ai-lab/github-ssh.conf -T ai-lab-github`. GitHub replied `Hi lehater! You've successfully authenticated`.
- Observed server Ed25519 fingerprint `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`; it matches the [published GitHub Ed25519 host fingerprint](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints).
- `bash bootstrap/host/verify.sh --auth` reported `S1 GitHub SSH authentication: PASS`.

- After the requested reboot, owner reported `bash bootstrap/host/verify.sh --local` with `S1 local config and proxied HTTPS: PASS`, and `bash bootstrap/host/verify.sh --auth` with `S1 GitHub SSH authentication: PASS`. This verifies **post-reboot SSH configuration, proxied HTTPS and authenticated Git transport** under the observed session. The log alone does not show whether the proxy started without user intervention.

- Owner ran `bash bootstrap/host/tests/test-configure.sh` on `lab-test`; output: `PASS: shell syntax, mocked config rendering, idempotency, safe conflict refusal.` This is an offline/mocked regression check, not a live network or new-clean-machine provisioning test.

- Follow-up code update in PR #5 added root Makefile tasks, an
  operator-guided SSH key setup, GitHub settings browser launch/fallback,
  and offline regression tests. Local mocked wizard tests passed outside
  `lab-test` (reuse, no overwrite, clipboard/browser actions and refusal
  of incomplete/symlink key paths). Earlier S1 configuration evidence refers
  to the preceding revision, not proof of this new Make/wizard workflow.
- Owner then ran the revised guided GitHub setup on `lab-test` (2026-10-21,
  partial console output provided). Wizard reported `Clipboard tool
  unavailable` (non-fatal), printed `https://github.com/settings/keys`,
  and reported that it sent the URL to the desktop browser; successful
  opening/loading of that page was not independently observed. Owner
  continued after GitHub key-registration prompt. Live SSH response:
  `Hi lehater! You've successfully authenticated`; proxied HTTPS PASS,
  authenticated Git SSH check PASS. This verifies the **revised wizard's
  interactive existing-key authentication path**, not first-time key creation,
  clipboard integration, or a clean-snapshot deployment.
- No complete S0→S1 installation trace after a clean reset has been provided yet.

- Owner ran `make host-test` on `lab-test` for the revised Make workflow:
  `test-configure.sh` passed, but `test-github-setup.sh` unexpectedly
  inherited an interactive terminal, prompted for live GitHub verification,
  then failed `ERROR: run make host-setup first` in its deliberately
  isolated temporary HOME. **This was an offline test isolation defect,
  not evidence of a broken host SSH setup.**
- Fix committed in PR #5: all mock wizard invocations in
  `test-github-setup.sh` explicitly use `</dev/null`, preventing TTY
  prompts and live network checks. On a separate local test environment,
  running the corrected `make host-test` under a pseudo-TTY as a
  non-root user produced both `PASS` lines (Shell/config/idempotency and
  mocked wizard preservation/browser/clipboard checks). Owner subsequently
  reran `make host-test` on `lab-test` and reported both expected PASS lines:
  `shell syntax, mocked config rendering, idempotency, safe conflict refusal`
  and `SSH wizard reuse, clipboard/browser guidance, no overwrite,
  incomplete/symlink protection, interactive opt-in`. This establishes
  regression success on that machine (the mock test does not prove GUI
  clipboard/browser behavior or a clean-snapshot S0→S1 run).

- Owner reported reverting `lab-test` to the known `vmware-tools-ready`
  VMware snapshot, then followed the S0 → S1 test instructions. The final
  post-reboot log shows `make host-verify` with
  `S1 local config and proxied HTTPS: PASS`; `make github-verify`
  showed `Hi lehater! You've successfully authenticated`, followed by
  another local HTTPS PASS and `S1 GitHub SSH authentication: PASS`.
  This confirms the target end-state on the recovered VM and working
  post-reboot SSH transport. The full S0/S1 installation output,
  current checked-out revision, and absence of manual proxy startup
  were not supplied in that log; these remain to be confirmed before
  certifying the whole replay.

- Owner explicitly confirmed after the `vmware-tools-ready` reset
  that the S0 bootstrap and first S1 SSH slice completed without errors and **v2rayN autostarted
  after reboot without manual intervention**. Together with the posted
  post-reboot `make host-verify` and `make github-verify` PASS logs,
  this supports the S0 autostart and first S1 SSH slice acceptance paths.
  The full installation transcript was not provided; distinguish
  owner attestation from complete retained machine evidence.
- Operator documentation gap found during replay: commands and their order
  still depended on reading a chat. PR #5 adds `bootstrap/README.md`
  as the single end-to-end USB-carried S0 → S1 runbook, with links from
  stage-specific and repository READMEs. Owner confirmed the physical USB
  was updated with the candidate runbook before merge; the final accepted
  revision will require a new copy to bring the on-disk guide up to date.

**Limits:** owner confirmed full clean-snapshot S0 → S1 completion and automatic proxy launch but did not provide the complete installation command/output transcript; the GitHub browser's actual page load and first-time new-key generation were not independently observed. First SSH transport slice is accepted via PR #5; complete S1 host provisioning and S1-D are not implemented/accepted by this evidence. Evidence derives from the owner's observations and logs, not remote execution by the assistant.

## Next work — S1-D Docker host candidate

- After accepted PR #5, the roadmap's **narrow functional S1 exit criterion**
  has owner-provided clean-VM setup, rerun, GitHub SSH and post-reboot evidence.
  Do not invent unspecified development tool requirements solely to keep S1
  open; milestone closure can be reviewed separately.
- [Draft PR #6](https://github.com/lehater/ai-lab/pull/6) proposes `bootstrap/docker/`: official Docker Engine /
  Compose installation with verified APT signing-key fingerprint, a
  dedicated systemd proxy drop-in, and `docker-test`, `docker-setup`,
  `docker-verify`, `docker-pull-test` Make targets.
- The owner fetched and checked out `feat/s1d-docker-host-proxy`
  on `lab-test` after accepted S0/S1; `make docker-test` reported:
  `PASS: Docker Shell syntax, stable APT repository template and daemon
  proxy template.` This validates **offline syntax/templates on the test VM**,
  not package installation, proxy/network reachability from Docker or daemon
  operation. Earlier local development-container test results remain separate.
- Owner then ran `make docker-setup` on `lab-test` and provided
  successful final output: `Docker Engine 29.9.2`,
  `Docker version 29.9.2, build a82e528`,
  `Docker Compose version v5.6.1`,
  `S1-D Docker host and daemon proxy: PASS (no image pull or container
  network checked)`, followed by `S1-D candidate: Docker Engine/Compose
  and daemon proxy configured; container networking/LAN security not yet
  verified`. This is **owner-provided installation and host/daemon-proxy
  success evidence**; complete APT installation logs were not provided.
- Owner then reran `make docker-setup` on `lab-test`, receiving
  `Docker Engine 29.9.2`, `Docker version 29.9.2, build a82e528`,
  `Docker Compose version v5.6.1`, and
  `S1-D Docker host and daemon proxy: PASS`. This supports **rerun
  compatibility** for the observed installed configuration; it is not
  a formal proof of full idempotency on every possible starting state.
- Owner immediately ran `make docker-pull-test`. The live daemon
  downloaded Docker Hub `library/hello-world:latest`, digest
  `sha256:11a3eb1597e864c51b3f56733cb2e8a90bf0c284bfc05f9444d81c558bc848aa`,
  and the container printed `Hello from Docker!`; the script reported
  `S1-D Docker registry pull and hello-world container: PASS.`
  This verifies authenticated or anonymous registry retrieval through
  the daemon's configured network path and container process execution,
  **not outbound HTTP(S) networking from a Docker bridge container**.
- After a reboot, owner provided `lab-test` console output for
  `make host-verify` (`S1 local config and proxied HTTPS: PASS`),
  `make docker-verify` (Docker Engine `29.9.2`, Docker Compose
  `v5.6.1`, daemon proxy PASS), and `make docker-pull-test`
  (same daemon PASS, proxy HTTPS PASS, Docker Hub `hello-world`
  already up to date, container prints `Hello from Docker!`,
  registry pull / container PASS). This verifies **post-reboot S0
  proxy connectivity, Docker daemon persistence, registry access and
  process startup** in the observed session. The latest log itself
  does not independently establish whether v2rayN was started
  automatically rather than manually; prior S0 autostart was separately
  confirmed in PR #5.
- Owner ran updated `make docker-test` on `lab-test`; it reported
  `PASS: Docker Shell syntax, stable APT repository template, daemon proxy
  template and bridge diagnostic contract.` Owner then ran
  `make docker-net-diagnose`. Observed:
  `xray` listens on **127.0.0.1:10808** (pid 3407);
  default Docker `bridge` gateway is **172.17.0.1**;
  `curlimages/curl:8.16.0` was pulled (digest
  `sha256:463eaf6072688fe96ac64fa623fe73e1dbe25d8ad6c34404a669ad3ce1f104b6`).
  Explicit proxy request from a bridge container via
  `host.docker.internal:10808` **failed** (`curl: (7)`, HTTP 000).
  A direct proxy-bypassing HTTPS request from the bridge container
  to `github.com` **succeeded (HTTP 200)**. The difference is
  consistent with the host listener bound to loopback only rather than
  to a bridge-reachable IP address, and confirms direct HTTPS
  bypass is possible on this Docker network. These are **observations
  on `lab-test`**, not evidence that Docker cannot use a future
  controlled proxy route or that LAN security has been proven.
- Still **not verified:** bridge-container proxied HTTP(S), enforced
  restriction of direct egress, negative LAN access from another host,
  Docker firewall behavior for published ports, or clean-snapshot
  S0 → S1 → S1-D replay. PR remains draft; `main` unchanged.
  Next evaluate a dedicated Docker `--internal` bridge with a
  bridge-interface-only forwarder to loopback Xray; keep the host
  Xray listener on `127.0.0.1`. Design and test before any permanent
  bridge listener/firewall change.

## Known environments

- **`lab`**: Ubuntu 24.04.5 Desktop / VMware, 8 vCPU, 16 GB RAM,
  150 GB ext4 disk. Manually configured v2rayN, GitHub SSH,
  Docker Engine/Compose, proxy networking and LAN isolation.
  See [observed environment](../current-environment.md).
- **`lab-test`**: separate Ubuntu 24.04.5 Desktop / VMware VM,
  100 GB virtual disk. Clean snapshot `vmware-tools-ready`
  (VMware Tools already installed) used for S0 recovery validation;
  baseline initially had neither Git nor v2rayN nor a running proxy.
- **Target later:** native Ubuntu (not yet validated by this bootstrap).
  Current S0 explicitly supports VMware only.

## Evidence and constraints

- S0 end-to-end checks on clean `lab-test`: v2rayN installed,
  Xray listened on `127.0.0.1:10808`,
  GitHub HTTP and SOCKS5 returned 200, APT installed packages,
  `git clone` of `lehater/ai-lab` succeeded, Stage 0 reported PASS.
- The initial Xray check failed once when Enter was pressed
  before manually opening v2rayN. This was an operator sequence issue:
  manual first GUI launch is documented and preserved by design.
- S0 success does **not** prove VMware Tools install from scratch,
  because the S0 test snapshot already contained VMware Tools.
- `docs/current-environment.md` reflects observed `lab` state
  and must not be read as clean-VM reproducibility evidence.
- No GitHub CI checks were configured for PR #1; machine tests were manual.

## Active work / handoff

1. S0 functional MVP is merged in `main`; avoid reopening its design
   without a demonstrated regression or requirement.
2. Next concrete candidate: **S1-D Docker Bootstrap** with a host
   daemon/registry slice, followed by separate bridge-container proxy
   and LAN security verification. Scope and gates are in [roadmap](roadmap.md).
3. Before claiming S1 acceptance, reset `lab-test` to the agreed
   baseline, run Stage 0, then execute S1 and verify on that machine.
4. S0 subsequent-login proxy autostart was confirmed by owner on clean-snapshot
   `lab-test` replay ([PR #5](https://github.com/lehater/ai-lab/pull/5)); keep the tested limits explicit.
5. [AI Lab strategy](strategy.md) was updated to the scenario-independent
   Enterprise-grade aspiration in [PR #4](https://github.com/lehater/ai-lab/pull/4)
   (superseding the scope from [PR #2](https://github.com/lehater/ai-lab/pull/2));
   this does not change any implementation/verification status above.

## Status vocabulary

- **NOT STARTED / NOT IMPLEMENTED**: no committed, verified implementation.
- **IN PROGRESS**: implementation underway, not accepted.
- **CONFIGURED, NOT VERIFIED**: code or settings exist, acceptance proof absent.
- **VERIFIED MVP**: the stated limited acceptance path was demonstrated.
- **DEFERRED / BLOCKED**: explicitly postponed / prevented by a dependency.

Only change a milestone to VERIFIED with an explicit test and evidence.
