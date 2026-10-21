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
| S0: subsequent-login GNOME autostart | **CONFIGURED, NOT INDEPENDENTLY VERIFIED ON `lab-test`** | `proxy/configure.sh` writes GNOME autostart; full post-reboot test on `lab-test` not reported. Main `lab` autostart was previously observed working. |
| S0: encryption and installer hardening | **DEFERRED** | Private proxy data is deliberately unencrypted for this functional MVP; physically protect storage; secrets stay out of Git. |
| S1: reproducible host bootstrap | **IN PROGRESS (draft PR #5), NOT VERIFIED** | First SSH transport candidate exists in `bootstrap/host/`. Owner-provided `lab-test` configuration, repeat-run, authenticated Git SSH and post-reboot `--local`/`--auth` checks passed. Full S1 provisioning and clean-baseline S0 → S1 replay remain pending. See the PR evidence below. |
| Docker/Compose bootstrap | **NOT IMPLEMENTED IN REPOSITORY** | Docker and container proxy operation were tested manually on `lab`, not automated for clean `lab-test`. |
| AI platform / model runtime | **NOT STARTED AS REPRODUCIBLE DEPLOYMENT** | No platform deployment code is present in `main` at this checkpoint. |
| Applications / experiments | **NOT STARTED IN THIS REPOSITORY** | No runnable end-to-end AI application committed yet. |

## Candidate S1 evidence — draft PR #5 (not accepted in `main`)

Owner-reported console evidence on `lab-test`, 2026-10-21, for [draft PR #5](https://github.com/lehater/ai-lab/pull/5):

- Fetched `feat/s1-host-ssh-transport` through S0 HTTP proxy; checked out branch.
- Ran `bash bootstrap/host/bootstrap.sh` twice: first created `~/.config/ai-lab/github-ssh.conf`, second reported existing configuration already matched. Each run reported `S1 local config and proxied HTTPS: PASS`.
- Registered a newly created SSH public key in GitHub via owner action; ran `ssh -F ~/.config/ai-lab/github-ssh.conf -T ai-lab-github`. GitHub replied `Hi lehater! You've successfully authenticated`.
- Observed server Ed25519 fingerprint `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`; it matches the [published GitHub Ed25519 host fingerprint](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints).
- `bash bootstrap/host/verify.sh --auth` reported `S1 GitHub SSH authentication: PASS`.

- After the requested reboot, owner reported `bash bootstrap/host/verify.sh --local` with `S1 local config and proxied HTTPS: PASS`, and `bash bootstrap/host/verify.sh --auth` with `S1 GitHub SSH authentication: PASS`. This verifies **post-reboot SSH configuration, proxied HTTPS and authenticated Git transport** under the observed session. The log alone does not show whether the proxy started without user intervention.

- Owner ran `bash bootstrap/host/tests/test-configure.sh` on `lab-test`; output: `PASS: shell syntax, mocked config rendering, idempotency, safe conflict refusal.` This is an offline/mocked regression check, not a live network or new-clean-machine provisioning test.

- Follow-up code update in draft PR #5 added root Makefile tasks, an
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
- No console output for the new `make host-test` target or repeat installation
  after a clean reset has been provided yet.

- Owner ran `make host-test` on `lab-test` for the revised Make workflow:
  `test-configure.sh` passed, but `test-github-setup.sh` unexpectedly
  inherited an interactive terminal, prompted for live GitHub verification,
  then failed `ERROR: run make host-setup first` in its deliberately
  isolated temporary HOME. **This was an offline test isolation defect,
  not evidence of a broken host SSH setup.**
- Fix committed in this draft PR: all mock wizard invocations in
  `test-github-setup.sh` explicitly use `</dev/null`, preventing TTY
  prompts and live network checks. On a separate local test environment,
  running the corrected `make host-test` under a pseudo-TTY as a
  non-root user produced both `PASS` lines (Shell/config/idempotency and
  mocked wizard preservation/browser/clipboard checks). **The corrected
  test has not yet been rerun on `lab-test`.**

**Limits:** no demonstrated reset immediately before these S1 tests, no full clean-snapshot S0 → S1 replay, no completed full S1 provisioning, and independent confirmation of proxy *automatic* launch after reboot still depends on observing that no manual start occurred. Existing S0 acceptance remains distinct. Evidence derives from the owner's logs, not remote execution by the assistant.

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
2. Next implementation milestone: **S1 Host Bootstrap** with small,
   independently testable modules; scope and gates are in
   [roadmap](roadmap.md).
3. Before claiming S1 acceptance, reset `lab-test` to the agreed
   baseline, run Stage 0, then execute S1 and verify on that machine.
4. Optional remaining S0 check: reboot `lab-test`, log into GNOME
   without manually starting v2rayN, verify Xray and proxied GitHub.
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
