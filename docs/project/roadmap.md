# Execution roadmap — AI Lab

**Updated:** 2026-10-20.  
**Purpose:** prioritize the next executable increment. This is an execution
plan and its acceptance gates; the [accepted AI Lab strategy](strategy.md) defines the Agentic SDLC focus and principles. Infrastructure milestones are enabling work, not a prerequisite for a bounded early SDLC experiment.

## Milestones

| Order | Milestone | Exit criterion |
| --- | --- | --- |
| S0 | Offline USB Bootstrap (VMware) | **VERIFIED MVP**: clean Ubuntu → proxy → APT/Git → GitHub clone. |
| S1 | Host Bootstrap | Reproducible baseline host configuration and GitHub development access, verified on `lab-test` after S0. |
| S1-D | Docker/Compose Bootstrap | Install/configure Docker through the proxy; test image pull and container networking through Xray on clean VM. |
| S2 | Infrastructure Core | Versioned service configuration, persistent-data placement, secret handling, diagnostics and one representative workload. |
| S3 | AI runtime | Bring up selected local/cloud model integrations as replaceable components with smoke checks. |
| S4 | Repeatable Agentic SDLC slice | At least two successive real changes to the same product accepted against a versioned requirements/architecture baseline; preserved prior constraints, traceability, independent checks, deviation handling and recorded effort. A later iteration must be reproducible from repository artifacts in a new context. |
| S5 | Broader orchestration/experiments | Compare simplest working execution to richer agent/human workflows before adding complexity. |

These are **engineering milestones**, not a commitment to a specific
orchestrator, model provider or infrastructure product.

## First vertical slice — controlled Agentic SDLC on AI Lab itself

**Focus:** validate preservation of engineering intent across successive changes to a real repository, **not** demonstrate a chat assistant or create a universal agent platform. Prefer one small, independently testable S1 Host Bootstrap component as the first actual change: the experiment and infrastructure work should be **the same work**, not two competing projects.

1. **Baseline:** record the relevant current requirements, architecture constraints/invariants, baseline revision and independent acceptance/regression checks. Reuse existing repository files; avoid introducing a separate documentation system.
2. **Change contract:** specify one real desired change, affected requirements, boundaries, permitted actions, protected criteria, human owner and expected evidence **before** implementation.
3. **Execution:** use the simplest viable human, script or coding-agent approach with available authorized tooling, without imposing a model, framework or orchestration service.
4. **Independent gate:** review PR/diff and run applicable functional, architectural and regression checks in a suitable environment. The implementer cannot silently relax protected criteria. Failure leads to repair or a separately authorized, recorded deviation.
5. **Traceability and evidence:** link requirement/decision → change/PR → verification result; record duration/cost where observable, human effort, defects and limitations.
6. **Continuity test:** repeat on a **second real change** of the same component/product in a new session or with a different executor, deriving context from the repository rather than a prior conversation. Verify that earlier requirements remain satisfied and measure rework.

**Earliest timing:** the initial controlled experiment may run alongside S1 when its particular checks are available; it does not require completing S1-D, S2 or S3 or deploying a local model. It **does not** replace the clean-VM infrastructure acceptance gates and cannot mark unfinished infrastructure VERIFIED. S4 is reached only after the repeated, accepted and documented change cycle, not after an isolated agent run. Keep independent S0 recovery possible.

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
- Full platform orchestration, multi-agent automation, broad AI applications
  and whole-SDLC automation before the smallest **repeatable Agentic SDLC** slice is validated. This does not block the bounded, independently checked experiment above.
