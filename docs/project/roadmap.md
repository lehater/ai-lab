# Execution roadmap — AI Lab

**Updated:** 2026-10-21.  
**Purpose:** incremental delivery toward an **Enterprise-grade engineering aspiration**, not a claim of current compliance. The [strategy](strategy.md) defines the scenario-independent infrastructure mission; [state](state.md) records what was actually verified.

## Milestones

| Order | Milestone | Exit criterion |
| --- | --- | --- |
| S0 | Offline USB Bootstrap (VMware) | **VERIFIED MVP, limited scope:** clean Ubuntu → proxy with documented manual first launch → APT/Git → GitHub clone. |
| S1 | Host Bootstrap | Versioned, rerunnable host configuration and GitHub development access verified on clean `lab-test` after S0. |
| S1-D | Docker/Compose Bootstrap | Reproducible Docker installation/proxy setup with clean-VM image pull and container network checks. |
| S2 | Infrastructure Core | Reusable, versioned module configuration, managed persistent data and secrets, diagnostics and verification of a representative service. |
| S3 | Pluggable AI capabilities | At least one independently installable/removable optional AI/runtime integration, with declared dependencies and smoke tests; no universal runtime requirement. |
| S4 | Reusable research environment template | A versioned composition of core/modules can be deployed from a declared baseline, checked and reset or removed; scenario is selected separately, not prescribed by strategy. |
| S5 | Maturity and portability increments | Evidence-based improvements to isolation, security, diagnostics, recovery and portability on explicitly chosen target environments. Record which properties were verified, not blanket Enterprise-grade status. |

**Milestones are implementation gates, not maturity labels or mandatory adoption of specific technologies.** Full Enterprise-grade maturity is a long-term engineering direction; it is not declared achieved on completion of any single milestone.

## First infrastructure vertical slice

Use current S1 Host Bootstrap as the next *small independently testable infrastructure improvement*: configuration in Git → command-driven provisioning → repeat/reboot checks → verification on `lab-test` → saved evidence. Document any necessary operator step rather than describing it as fully unattended IaC.

Reusable modules and templates should be built from observed needs, not from a preselected AI scenario. A research project may independently use the lab at any stage for which its prerequisites and checks are available; such use does not change the laboratory mission or prematurely complete a milestone.

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

- Secure encrypted backup of private proxy data, signed/reproducible offline payload distribution and archive extraction hardening; risk and treatment remain explicit.
- Other hypervisors, bare-metal support, GPU/runtime hosting and portability checks until targeted and verified.
- Full orchestration, multi-agent stacks, broad service catalogues and centralized tooling absent a concrete research/infrastructure need.
- Enterprise-wide controls (advanced policy, centralized observability, comprehensive CI/CD) beyond the validated small infrastructure slices. Introduce them progressively when value and risks warrant; never claim they already exist.
