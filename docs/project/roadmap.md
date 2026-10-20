# Execution roadmap — AI Lab

**Updated:** 2026-10-20.  
**Purpose:** prioritize the next executable increment. This is an execution
plan and its acceptance gates; the [AI Lab strategy](strategy.md) defines the primary focus and principles (reviewed in PR #2).

## Milestones

| Order | Milestone | Exit criterion |
| --- | --- | --- |
| S0 | Offline USB Bootstrap (VMware) | **VERIFIED MVP**: clean Ubuntu → proxy → APT/Git → GitHub clone. |
| S1 | Host Bootstrap | Reproducible baseline host configuration and GitHub development access, verified on `lab-test` after S0. |
| S1-D | Docker/Compose Bootstrap | Install/configure Docker through the proxy; test image pull and container networking through Xray on clean VM. |
| S2 | Infrastructure Core | Versioned service configuration, persistent-data placement, secret handling, diagnostics and one representative workload. |
| S3 | AI runtime | Bring up selected local/cloud model integrations as replaceable components with smoke checks. |
| S4 | Repeatable self-development workflow | Reuse the thin-slice process on a second real AI Lab change; both changes accepted with independent checks and recorded effort. |
| S5 | Broader orchestration/experiments | Compare simplest working execution to richer agent/human workflows before adding complexity. |

These are **engineering milestones**, not a commitment to a specific
orchestrator, model provider or infrastructure product.

## First vertical slice — develop AI Lab using AI Lab

**Focus:** make the lab its own first consumer (dogfooding), without building a
universal agent platform first. Target a small real change in this repository
(e.g., an independently testable S1 Host Bootstrap module), not a toy chat.

- **Contract:** describe the task, inputs, constraints, permitted tools and
  acceptance checks **before** execution.
- **Executor:** use the simplest viable human, script or coding-agent route,
  including approved subscription-based CLI or local model if useful; avoid
  requiring a new orchestration layer.
- **Output:** code/documentation in a branch and PR, linked to the task.
- **Independent gate:** review and reproducible checks on the designated
  environment before acceptance; no agent self-approval of its own changes.
- **Evidence:** record result, failures, time/cost where observable, human
  intervention and whether the next comparable change gets easier.

**Earliest timing:** an exploratory thin slice may proceed alongside S1/S1-D
when its environment and tests are ready. It **does not** replace the S1/S1-D
clean-VM gates and cannot mark unfinished infrastructure VERIFIED. S4 is the
milestone for a **completed, accepted** application workflow, not a prerequisite
for trying a small task earlier. The early thin slice alone does not complete
S4: S4 verifies reuse on another task. Keep independent Stage 0 recovery possible.

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
- Full platform orchestration, multi-agent automation and broad application
  development before the smallest infrastructure slice is stable; this does
  not block the limited, independently checked dogfooding experiment above.
