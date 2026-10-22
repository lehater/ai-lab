# Proposal: Agent-driven workflow automation spike (Codex + n8n MCP)

**Status:** EXPERIMENTAL IMPLEMENTATION IN BRANCH — not accepted or verified on lab-test.
**Baseline:** accepted main, S0 → S1 → S1-D Docker/Compose functional replay on lab-test. S2 and S3 are not verified.
**Scope:** disposable research experiment; no permanent Infrastructure Core component.

## Problem and decision to inform

AI Lab can reproduce host and Docker/Compose setup, but has not established whether a coding agent can reliably **author, modify, test and reproduce application workflows** through a supported external workflow engine. The four externally supplied instructions for VPS/n8n/LiteLLM/Eggent show a plausible approach, but do not provide verified AI Lab deployment or portable workflow artifacts.

**Research question:** Is the official built-in n8n instance-level MCP interface plus Codex a useful, reproducible optional automation capability for future research environments?

This is **not** a proposal to orchestrate S0/S1/bootstrap through n8n. Make, shell and Compose remain the independent bootstrap/recovery path. n8n is a candidate **consumer** of S2 infrastructure primitives and eventually an **optional** S3 module, not a mandatory control plane.

## Scope and boundaries

- Runtime: isolated **self-hosted n8n** in a short-lived Docker Compose project on lab-test, using its bundled/default database and a project-scoped persistent volume. No PostgreSQL, Supabase, LiteLLM, Eggent, public VPS or reverse proxy.
- Network: publish the editor/MCP port **only on 127.0.0.1** of the test machine. Verify actual host binding. Do not assume local-only binding establishes LAN isolation.
- Client: **Codex CLI** with official n8n built-in MCP. Codex was **absent on lab-test** after S1-D; the experimental branch now includes `experiments/workflow-automation-n8n/codex-setup.sh` to install pinned `@openai/codex@0.163.0` in the operator's home directory using Ubuntu APT for missing Node/npm and S0's npm proxy. Run Codex in the same VM or explicitly document an operator-controlled transport from the Codex host; never assume localhost on a remote agent refers to lab-test.
- Identity: operator creates the n8n owner and enables instance-level MCP, then issues an **MCP API key** (not the separate n8n public REST API key). Those steps are manual prerequisites, not unattended installation.
- Secrets: MCP token and n8n encryption key outside Git; Codex HTTP MCP bearer token read from a local environment variable, never embedded in the repo or logs. Use an isolated instance and explicitly approve state-changing MCP operations.
- Versioning: fix and record a concrete n8n image version/digest for the trial, installed Codex version, Workflow SDK/tool capabilities, and baseline Git SHA.
- No external services, real customer data, privileged Docker API, scheduled outbound messages, or broad credentials in the test workflow.

## Distinct automation layers

| Layer | Responsible system | Input / output |
| --- | --- | --- |
| Infrastructure provisioning | Git-controlled shell/Make/Compose | Baseline + config → running disposable n8n |
| Workflow authoring | Codex through official n8n MCP | Task + requirements → validated workflow definition |
| Workflow execution | n8n | Trigger/test input → execution and result |
| Provenance and replay | Git artifacts + acceptance scripts | Definition + revision → reproducible behavior |

MCP is a **control interface**, not the workflow execution engine. No agent process is required to keep executing a published workflow.

## Two-stage experiment with an early exit

### Stage A — prove agent-driven authoring before investing in a module

1. On lab-test, record Git HEAD, Docker/Compose and n8n image identity, and verify S1-D prerequisites. Install/verify Codex with the experimental user-local script; operator signs in with ChatGPT or another supported method. Record Node/npm/Codex versions and whether the proxy works. Do not mark authentication complete until actually tested.
2. Start an isolated n8n Compose project with a project-scoped volume and loopback-only binding. Record container startup/health and port exposure. Do not change existing AI Lab Docker proxy or default networking decisions (D-011).
3. Operator initializes the owner account, enables Instance-level MCP, creates the instance MCP token. Configure Codex Streamable HTTP MCP with a **local** bearer-token environment variable. Confirm MCP tool discovery; record names and count, not tokens.
4. Ask Codex to construct a **manual/test-triggered** workflow without outside dependencies. Example: a fixed input value 4 is transformed to value 8, with a machine-checkable JSON result.
5. Require Codex to inspect node/tool references as needed, validate, create and test the workflow via MCP; fix reported errors. No manual editing of nodes in the n8n canvas.
6. Ask Codex to change the multiplier so the result becomes 12, validate again, execute and confirm the expected output. Capture both workflow definitions/versions and execution IDs.
7. Collect failures, number of operator actions, elapsed time and exact interventions. If MCP authoring or execution cannot be demonstrated, **stop and document the failure**; do not build a reusable module.

**Stage A pass:** create → validate → execute → update → re-validate → execute all work through Codex/MCP, results match 8 and 12, no unintended external calls or exposed listener. A hand-built workflow or a one-time successful UI screenshot is not sufficient.

### Stage B — prove portable, Git-backed reproduction (only after Stage A)

1. Export/save a reviewable workflow artifact (Workflow SDK source and/or n8n workflow JSON, based on actual supported tool/CLI paths). Sanitize and check for credential references, instance IDs and sensitive data.
2. Destroy **only the experiment-owned** Compose project and data volume after capturing needed evidence. Recreate with an independent fresh volume and the same pinned version. Complete any n8n owner/MCP setup manually and record it.
3. Re-import or recreate from the versioned artifact, **without manual node construction**, and run the same test cases. Compare normalized workflow structure and observable outputs rather than volatile instance-generated IDs.
4. Check restart/persistence in the first instance separately if relevant, then verify clean project-scoped removal (containers, project networks and project volumes). Never use global Docker prune commands.
5. Record image digest, Git revision, commands, PASS/FAIL outputs, all manual steps, time, resource impact and limitations.

**Stage B pass:** a clean, operator-assisted deployment reconstructs the workflow from files committed in the experimental branch and reproduces the same test result; independent teardown leaves no experiment resources. This does not prove unattended recovery, production security or a generic backup solution.

## Acceptance, decision and risks

| Priority | Check / risk | Required evidence or treatment |
| --- | --- | --- |
| P1 | n8n MCP tool/version mismatch | Discover actual tools before relying on named methods; fail clearly when unavailable |
| P1 | Agent alters workflows outside the experiment | Use an isolated instance and explicit approvals for writes/publish; never share production credentials |
| P1 | Nonreproducible n8n database-only state | Save a workflow artifact in Git and prove replay on a fresh instance |
| P1 | Accidental port exposure | Bind to 127.0.0.1, inspect Docker port configuration and host listeners |
| P1 | Credentials leakage | Env-managed token outside Git, redact logs, scan artifacts before commit |
| P2 | Moving dependencies / incompatible nodes | Capture n8n image digest, Codex version and node/SDK versions |
| P2 | Complexity with no consumer | Compare results against an equivalent shell/Python or Make workflow; defer module if no benefit |

**Adoption decision:** consider a small independently installable S3 n8n module **only if** both stages pass and there is an actual research consumer needing triggers, connectors, approvals or persistent execution. If the use case is simply host setup, tests and CI, keep Make/Compose and optional GitHub Actions; do not add n8n.

**Candidate outcomes:** (a) validated optional module; (b) useful one-off experiment with explicit limitations; (c) no adoption because agent/MCP workflow authoring fails or adds unjustified operational cost. These are outcomes to decide **after** evidence, not current project state.

## Not proposed

The branch now contains a disposable n8n Compose harness, scoped Bash lifecycle script, static checks, an operator runbook and a Codex authoring task under `experiments/workflow-automation-n8n/`. This is **preparation, not a live test**. No change to accepted strategy, roadmap, state, decisions, S0–S1-D bootstrap scripts or Docker networking baseline. No permanent database or orchestration service. No automatic acceptance, merge, publication or production deployment.

## Source documentation and constraints

- AI Lab: AGENTS.md; docs/project/{strategy,state,roadmap,decisions}.md; D-010/D-011.
- Official n8n MCP: https://docs.n8n.io/connect/connect-to-n8n-mcp-server
- Official n8n MCP tools: https://docs.n8n.io/connect/connect-to-n8n-mcp-server/mcp-server-tools-reference/
- Official n8n announcement: https://blog.n8n.io/n8n-mcp-server/
- Codex MCP client and bearer-token configuration: https://learn.chatgpt.com/docs/extend/mcp?surface=cli

**Current evidence:** Docker/Compose + n8n 2.44.5 startup and HTTP health were owner-verified on lab-test on 2026-10-22 (see `experiments/workflow-automation-n8n/evidence/2026-10-22-lab-test-bootstrap.md`). Codex installation, login, MCP access, agent-authored execution and clean-instance replay remain **NOT TESTED**.
