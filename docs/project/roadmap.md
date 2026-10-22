# Execution roadmap — AI Lab

**Updated:** 2026-10-22.  
**Purpose:** incremental delivery toward an **Enterprise-grade engineering aspiration**, not a claim of current compliance. The [strategy](strategy.md) defines the scenario-independent infrastructure mission; [state](state.md) records what was actually verified.

## Milestones

| Order | Milestone | Exit criterion |
| --- | --- | --- |
| S0 | Offline USB Bootstrap (VMware) | **VERIFIED MVP, limited scope:** clean Ubuntu → proxy with documented manual first launch → APT/Git → GitHub clone. |
| S1 | Host Bootstrap | Versioned, rerunnable host configuration and GitHub development access verified on clean `lab-test` after S0. |
| S1-D | Docker/Compose Bootstrap | Reproducible Docker Engine/Compose installation, daemon proxy for registry pulls, container startup and ordinary Compose networking, with clean-VM rerun/reboot evidence; no compulsory container egress proxy. |
| S2 | Infrastructure Core | Reusable, versioned module configuration, managed persistent data and secrets, diagnostics and verification of a representative service. |
| S3 | Pluggable AI capabilities | At least one independently installable/removable optional AI/runtime integration, with declared dependencies and smoke tests; no universal runtime requirement. |
| S4 | Reusable research environment template | A versioned composition of core/modules can be deployed from a declared baseline, checked and reset or removed; scenario is selected separately, not prescribed by strategy. |

**Milestones are functional delivery gates, not maturity labels or a mandatory technology stack.** Enterprise-grade is the long-term engineering aspiration and applies **across all stages**; completing S4 does not prove it has been achieved.

## Cross-cutting engineering maturity

Develop in **two dimensions**: (1) deliver functional infrastructure increments S0–S4; (2) strengthen the applicable engineering properties **within every increment**. Do not defer baseline quality, security or verification until the infrastructure is feature-complete.

For each new or changed module/template, use a risk- and scope-appropriate acceptance contract:

| Engineering dimension | Minimum expectation, progressing with scope |
| --- | --- |
| **IaC & change control** | Version configuration and deployment code in Git; record versions, dependencies and explicitly required manual steps; review changes through PRs. |
| **Reproducibility & automation** | Provide controlled installation/configuration commands and a declared baseline; test reruns, reboot persistence or teardown **only where the change's own contract or concrete risk requires it**. |
| **Verification** | Define independent, repeatable acceptance checks and retain results with the environment/revision; do not confuse writing a check with successfully running it. |
| **Security** | Keep secrets outside Git, minimize privileges and exposed network surfaces, evaluate risk, document deliberate deferrals and test relevant boundaries. |
| **Operability & recovery** | Provide sufficient diagnostics to identify failures, an appropriate reset/rollback or recovery procedure, and explicit known limitations. |
| **Portability** | Isolate environment-specific settings; state exactly which operating systems/hypervisors have actually been tested. Extend support only after verification. |

The depth of these controls grows with **risk, complexity and reuse**, not with a calendar or a fixed certification checklist. CI, centralized observability, advanced policy and other enterprise practices are candidates for incremental adoption when a concrete control gap justifies them.

### Risk-based verification: test our uncertainty, not known platform features

Before adding an acceptance test, write down **the specific failure in our code/configuration that the test can detect**. Use official upstream documentation for mature, already-supported capabilities such as Docker volumes, PostgreSQL dump/restore, APT and Ansible modules; do not rebuild vendor conformance suites.

- **Standard documented behavior:** cite the contract, no proof-of-technology experiment. A static `config` or syntax check is enough when the work merely expresses a known configuration.
- **Our integration:** one smallest decisive end-to-end check of the uncertainty (for example, *our* dump restored into **different empty storage** and actually queried), not repeated demonstrations of individual Docker/PostgreSQL primitives.
- **Risky actions** (secrets, destructive cleanup, data loss, trust boundaries): keep narrow preconditions/guards and verify the failure mode where we introduce custom logic. Avoid unrelated certification-style test matrices.
- **Regression:** rerun affected accepted checks only when the change can actually alter that contract; do not reflexively replay the entire S0 → S1-D clean-VM bootstrap for an isolated Compose fixture.
- **Evidence:** record one real PASS/FAIL with revision/environment and explicit limits. A documented feature is not evidence that *our script* ran; an unexecuted pilot is not VERIFIED.

Tests should be proportionate to change risk and answer concrete acceptance questions; **test volume is not a maturity metric**. Do not introduce a second component merely to test an already-proven installer abstraction.

**Stage-specific verification emphasis** (additive, not a replacement for the cross-cutting contract):

| Stage | Additional engineering evidence |
| --- | --- |
| **S0** | Existing clean-`lab-test` recovery evidence remains **VERIFIED MVP** only for its specified path; manual first launch, owner-verified GNOME autostart and deferred hardening stay explicit. New maturity requirements do not retroactively invalidate or upgrade S0. |
| **S1** | Repeatable host configuration, idempotent rerun, reboot checks and safe developer access on clean `lab-test`. |
| **S1-D** | Reproducible Docker install/daemon proxy, image pull, container and Compose smoke tests, rerun/reboot from clean `lab-test`; negative exposure checks for enabled Docker APIs/published ports, with external LAN verification when making LAN-safety claims. Container proxy-only egress is a separate optional workload requirement. |
| **S2** | Module boundaries, configuration/secrets and persistent-data lifecycle, representative service health/diagnostics and recovery checks. |
| **S3** | Optional AI integration installs and verifies independently, with explicit dependencies, secrets and clean removal/disable behavior. |
| **S4** | Compose an environment from reusable modules; reproduce it from a declared baseline, verify isolation and reset/teardown, and record reuse effort. |

Record actual pass/fail evidence and remaining gaps in [state](state.md), not a speculative aggregate Enterprise-grade score. **Maturity work continues after S4** without requiring a new numbered final stage.

## Current S2 — accepted host-manager first slice; core gates still open

**Accepted baseline:** S0 → first S1 GitHub SSH module → S1-D Docker/Compose are owner-verified in their recorded scopes. The historical S1 setup/replay procedure is retained below as evidence; repeating it is a regression check, **not** a reason to restart the S1 milestone.

**Accepted first host-manager slice:** [merged PR #15](https://github.com/lehater/ai-lab/pull/15) provides a pinned, local Ansible Core controller, localhost inventory and an owner-tested `ripgrep` installation/verify/rerun/cleanup lifecycle. Decision **D-012** accepts Ansible as the S2 mechanism for *new optional host-managed components*. This does **not** retroactively make Ansible necessary to run the existing S0/S1/S1-D bootstrap, replace Compose, or certify the complete S2 milestone.

**Current priority:** [PR #19 — optional VS Code role](https://github.com/lehater/ai-lab/pull/19) is **closed without merge**: no identified consumer needs managed VS Code deployment; the already accepted Ansible role does not require further artificial demonstrations. [Draft PR #20 — minimal backup/restore integration](https://github.com/lehater/ai-lab/pull/20) remains an **unverified candidate**. Its only decisive runtime question is whether **our own script** creates a backup and correctly restores its known data into a separate empty volume. PostgreSQL is only a disposable test fixture, not a required AI Lab database. Do not merge or claim S2 acceptance without observing that integration result.

**Remaining initial Ansible pilot evidence gaps:** negative scenario for a pre-existing unmanaged `ripgrep`, explicit post-reboot package functional verification, repeat controller-bootstrap and pipx dependency freeze; track independently without delaying unrelated S2 work.

## Historical proposed S2/S3 probes — deferred, not accepted implementation

Two earlier candidates are not active infrastructure work; their untested code and platform-specific choices are **not merged into `main`**:

- [PR #9 — stateful Docker Compose pilot](https://github.com/lehater/ai-lab/pull/9) was closed **without merge** and **without `lab-test` runtime validation**. The portable *acceptance questions* remain useful for S2: a representative stateful service should demonstrate private secret handling, health/readiness, persistent data across recreation, scoped backup and restoration into **separate fresh storage**, no unintended published ports, and complete **project-specific** teardown without global `docker prune`. A disposable PostgreSQL 17 fixture was one proposed test mechanism, **not** a database requirement or a proven recovery system. Do not represent planned smoke scripts as actual PASS results.
- [PR #10 — first optional local inference candidate](https://github.com/lehater/ai-lab/pull/10) proposed a disposable **Ollama CPU** probe (`qwen3:1.7b`) on the Docker baseline; it was **not run, accepted or selected as a mandatory S3 module**. Valuable future checks: a named AI consumer, RAM/CPU/disk and model download viability, exact image/model versions and digests, response correctness/latency, and bind-only-to-loopback API exposure. In particular, **Docker daemon registry proxying does not automatically provide outbound network access from inside a model container**. Do not weaken the host proxy or expose the unauthenticated Ollama API on LAN merely to get a demo running. Select the concrete model/runtime later when a consumer justifies it.

These are **deferred verification requirements**, not an instruction to resume either old PR or preserve their working branches. Small clean-environment tests should be proposed anew once their requirements are relevant.

## S1-D — functional integrated replay verified on lab-test

The first S1 GitHub SSH transport slice is accepted in PR #5, with owner
evidence for its stated functional criteria. Do not invent host tooling
just to extend the milestone. The first module was accepted in
[PR #6](https://github.com/lehater/ai-lab/pull/6).

**Scope:** official Docker Engine/Compose APT installation; a dedicated
systemd daemon proxy using S0's Xray; image pull/container execution,
rerun, reboot and normal Compose bridge networking.
Docker's daemon proxy does **not** configure application-level proxying.
A container's ability to reach the internet directly is not in itself
a failure of this baseline.

**Owner-verified first slice:** Engine/Compose install and rerun,
daemon proxy, image pulls, normal Compose bridge lifecycle/cleanup
and reboot checks on `lab-test`. A final local port check found no
running published containers or Docker API listeners on 2375/2376.

**Integrated functional acceptance — owner-verified (2026-10-22):**
After restoring `lab-test` to `vmware-tools-ready`, the owner
explicitly confirmed running the full scripted S0 → S1 → Docker
installation, then supplied final GitHub SSH, Docker Engine/Compose,
registry pull and Compose service/network cleanup PASS outputs.
Functional reproducibility is established on this VMware/Ubuntu target.
See [project state](state.md) for evidence and qualifiers.

**Independent limits:** the first Xray GUI start and GitHub key
enrollment require operator action; no unattended installation,
package-version pinning, other hypervisor support, or external
LAN-isolation verification is claimed. No mandatory container
proxy-only routing is required (D-011).

**Deliberately deferred (D-011):** a forced-proxy-only network,
Docker `--internal` app egress restrictions, bridge-scoped forwarders
and general firewall machinery without a concrete consumer and threat
model. Earlier experiments remain recorded in
[state](state.md), but their bespoke tools are not part of the
S1-D bootstrap.

## Deferred

- Secure encrypted backup of private proxy data, signed/reproducible offline payload distribution and archive extraction hardening; risk and treatment remain explicit.
- Other hypervisors, bare-metal support, GPU/runtime hosting and portability checks until targeted and verified.
- Full orchestration, multi-agent stacks, broad service catalogues and centralized tooling absent a concrete research/infrastructure need.
- Enterprise-wide controls (advanced policy, centralized observability, comprehensive CI/CD) beyond the validated small infrastructure slices. Evaluate each as an incremental cross-cutting improvement when value and risks warrant; never claim it is already implemented.
