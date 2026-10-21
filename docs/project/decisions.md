# Accepted engineering decisions — AI Lab

**Updated:** 2026-10-21.  
This is a lightweight decision log, not a second strategy document.
Entries describe **accepted engineering choices**. New proposals stay in PRs until approved.

| ID | Decision | Reason / boundary |
| --- | --- | --- |
| D-001 | `main` is the source of accepted project state; `AGENTS.md` points to current state, roadmap and decisions. | Continuity across chats and agents; a conversation is not durable state. |
| D-002 | Work in Git, test on independent `lab-test`; keep `lab` as development/reference environment. | Distinguish reproducible setup from previously hand-configured host. |
| D-003 | S0 currently targets Ubuntu 24.04 Desktop **VMware**, amd64. | One validated platform before generalizing to bare metal and other hypervisors. |
| D-004 | Public S0 code and private proxy payload share the same directory layout on GitHub/USB. Git tracks only `private-proxy/README.md`; three actual payload files are local-only. | No repacking, renamed paths, or private data in Git. |
| D-005 | v2rayN is launched **manually once** during first bootstrapping; `configure.sh` configures GNOME autostart for later sessions. No separate `start.sh`. | Keep the functional MVP simple; selection of a server remains an operator step. |
| D-006 | Stage 0 obtains GitHub source using **public HTTPS clone through Xray**, without requiring SSH authentication first. | Avoid dependency cycle: Git access is needed before host/developer configuration. |
| D-007 | Encryption/hardening of the protected offline proxy payload is deferred until after the first functional MVP. | Prioritize verified end-to-end path; protect unencrypted storage and never commit secrets. |
| D-008 | S1 Host Bootstrap and Docker Bootstrap are separate later responsibilities; S0 ends once proxy, APT and Git access work. | Avoid overloading USB recovery with general host/runtime provisioning. |
| D-009 | [AI Lab strategy](strategy.md) accepted by owner on 2026-10-20 ([PR #2](https://github.com/lehater/ai-lab/pull/2)). | AI Lab first develops itself through independently verified human/agent work; tool choices are evidence-based, security and acceptance gates remain independent. Strategy acceptance does not imply any AI runtime is implemented or any specific framework is selected. |
| D-010 | AI Lab is a **scenario-independent AI research infrastructure lab**; **Enterprise-grade is the long-term target**, approved by owner on 2026-10-21 ([PR #4](https://github.com/lehater/ai-lab/pull/4)). | Prioritize IaC, versioned and command-driven deployment, reusable modules/templates, reproducible verification, security and observability in incremental, independently checked stages. No current overall Enterprise-grade claim. Specific research areas including Agentic SDLC are consumers, not mission. Supersedes the scenario-specific focus of D-009 while preserving its engineering governance. |

## Non-decisions and open proposals

- The [strategy](strategy.md) sets the enterprise-engineering direction for reusable research infrastructure; specific AI scenarios, runtime, model, agent, workflow and integration choices remain open.
- Specific S1 module contracts, Docker networking strategy and persistent
  secret handling need implementation-level review.
- Do not infer architectural decisions for AI agents or orchestration from
  successful S0 infrastructure tests.

## Adding a decision

Append a short ID and clear boundary when the owner accepts a change;
cite the implementing PR/test where appropriate. Supersede a decision
explicitly rather than silently rewriting project history. Record
experiments and failed tests in [state](state.md), not as new decisions.
