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
| S1: reproducible host bootstrap | **NOT IMPLEMENTED IN REPOSITORY** | Manual setup exists on `lab`; scripts/tests for full S1 still need to be written. |
| Docker/Compose bootstrap | **NOT IMPLEMENTED IN REPOSITORY** | Docker and container proxy operation were tested manually on `lab`, not automated for clean `lab-test`. |
| AI platform / model runtime | **NOT STARTED AS REPRODUCIBLE DEPLOYMENT** | No platform deployment code is present in `main` at this checkpoint. |
| Applications / experiments | **NOT STARTED IN THIS REPOSITORY** | No runnable end-to-end AI application committed yet. |

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
5. [AI Lab strategy](strategy.md) was accepted by the owner in
   [PR #2](https://github.com/lehater/ai-lab/pull/2); it does not change the
   implementation/verification status above.

## Status vocabulary

- **NOT STARTED / NOT IMPLEMENTED**: no committed, verified implementation.
- **IN PROGRESS**: implementation underway, not accepted.
- **CONFIGURED, NOT VERIFIED**: code or settings exist, acceptance proof absent.
- **VERIFIED MVP**: the stated limited acceptance path was demonstrated.
- **DEFERRED / BLOCKED**: explicitly postponed / prevented by a dependency.

Only change a milestone to VERIFIED with an explicit test and evidence.
