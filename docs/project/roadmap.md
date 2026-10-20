# Execution roadmap — AI Lab

**Updated:** 2026-10-20.  
**Purpose:** prioritize the next executable increment. This is an execution
plan, not the unaccepted [strategy proposal](https://github.com/lehater/ai-lab/pull/2).

## Milestones

| Order | Milestone | Exit criterion |
| --- | --- | --- |
| S0 | Offline USB Bootstrap (VMware) | **VERIFIED MVP**: clean Ubuntu → proxy → APT/Git → GitHub clone. |
| S1 | Host Bootstrap | Reproducible baseline host configuration and GitHub development access, verified on `lab-test` after S0. |
| S1-D | Docker/Compose Bootstrap | Install/configure Docker through the proxy; test image pull and container networking through Xray on clean VM. |
| S2 | Infrastructure Core | Versioned service configuration, persistent-data placement, secret handling, diagnostics and one representative workload. |
| S3 | AI runtime | Bring up selected local/cloud model integrations as replaceable components with smoke checks. |
| S4 | First application experiment | One useful end-to-end software-engineering workflow with observable output and acceptance checks. |
| S5 | Broader orchestration/experiments | Compare simplest working execution to richer agent/human workflows before adding complexity. |

These are **engineering milestones**, not a commitment to a specific
orchestrator, model provider or infrastructure product.

## Next iteration — S1 Host Bootstrap

**Objective:** On the `lab-test` VMware Ubuntu that has completed S0,
prepare a usable, secure, reproducible development host **without relying
on machine-local undocumented actions**.

Proposed thin slice:

1. Define `bootstrap/host/` entrypoint and module boundaries:
   prerequisites, configurable inputs, idempotence, and `verify.sh`.
2. Configure/verify developer tooling and **GitHub SSH through proxy**,
   including a user-authorized public-key registration procedure.
   Public HTTPS clone already works in S0; avoid repeating it.
3. Keep host networking/apt baseline compatible with S0 and document
   which settings belong to which stage; do not duplicate proxy installation.
4. Verify the host module on `lab-test` and rerun it to catch
   unintended overwrites.

**Acceptance:** from the S0-completed test snapshot, host bootstrap runs
and passes its stated checks; configuration survives reboot where relevant;
rerun does not damage existing settings. Record exact commands, output and
limitations in [state](state.md).

## Then — S1-D Docker

- Script Docker Engine/Compose installation and daemon proxy setup.
- Verify daemon image pulls; verify container HTTP(S) access through
  `host.docker.internal:10808` or the selected explicit bridge route.
- Prevent LAN exposure of the proxy and validate the firewall rules on
  the target interface; avoid blindly reusing `lab`-specific interface names.
- Reset `lab-test`, rerun S0 → S1 → Docker, capture results and
  update [state](state.md).

## Deferred

- Secure encrypted backup of private proxy data, signed/reproducible
  offline payload distribution, tar archive extraction hardening.
- Other hypervisors, bare-metal support, GPU runtime and model serving.
- Full CI, platform orchestration, applications and multi-agent workflows
  before the smallest infrastructure slice is stable.
