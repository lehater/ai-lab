# lab-test — n8n bootstrap smoke, 2026-10-22

**Environment:** `lab-test` (operator-provided console output), experimental branch `proposal/workflow-automation-mcp-spike`.
**Scope:** Stage A infrastructure bootstrap **verified by owner-provided terminal log**. MCP authentication and workflow authoring **not yet tested**.

## Actual operator commands and observations

Operator executed the experiment's `make docker-verify`, `lab.sh static-test`, `lab.sh up`, and `lab.sh verify` sequence and provided these sanitized results:

```text
Docker Engine 29.9.2
Docker version 29.9.2, build a82e528
Docker Compose version v5.6.1
S1-D Docker host and daemon proxy: PASS (no image pull or container network checked).
PASS: static shell and scoped n8n Compose expectations.
Generated private local encryption key file (contents hidden).
Image docker.n8n.io/n8nio/n8n:2.44.5 Pulled
Network ailab-n8n-mcp-spike_default Created
Volume ailab-n8n-mcp-spike_n8n_data Created
Container ailab-n8n-mcp-spike-n8n-1 Started
PASS: n8n HTTP health endpoint at http://127.0.0.1:5678/healthz
Operator setup: open http://127.0.0.1:5678, create owner, then enable Settings > Instance-level MCP.
PASS: n8n HTTP health endpoint at http://127.0.0.1:5678/healthz
PASS: Compose config, container, loopback port and local health.
```

## Acceptance status

| Check | Status | Evidence |
| --- | --- | --- |
| Docker/Compose prerequisites | **PASS** | Docker 29.9.2, Compose 5.6.1, existing S1-D verification |
| Offline shell / Compose expectation check | **PASS** | `PASS: static shell and scoped n8n Compose expectations` |
| n8n Docker image pull | **PASS** | Successful image pull of explicit tag 2.44.5 |
| Disposable Compose project/network/volume/container | **PASS** | Docker `up` results |
| Local HTTP health | **PASS** | `/healthz` success after `up` and `verify` |
| Loopback-only declared/published port | **PASS (local check)** | `lab.sh verify` verifies `docker compose port n8n 5678` equals `127.0.0.1:5678`; not an external LAN scan |
| Exact experiment checkout commit SHA | **NOT RECORDED** | Operator did not include `git rev-parse HEAD` in this transcript |
| Pulled image digest / ID | **NOT RECORDED** | Pull succeeded, immutable image identity absent |
| n8n owner and instance-level MCP enablement | **NOT TESTED** | Manual operator action next |
| Codex CLI 0.163.0 installation / binary | **PASS (operator output)** | Experiment-local `codex-setup.sh verify` reports pinned version; subsequent `codex --version` also returns `codex-cli 0.163.0` |
| Codex ChatGPT login / authentication | **PASS (operator output)** | `codex login status` returned `Logged in using ChatGPT`; n8n MCP not tested |
| Codex n8n MCP tool discovery | **PASS (operator excerpt)** | n8n-specific MCP tool names surfaced in Codex; truncated partial list |
| Codex MCP read-only tool invocation / authorization | **NOT TESTED** | No actual MCP tool response supplied yet |
| Agent-authored workflow create/execute/update/execute | **NOT TESTED** | Stage A main research gate |
| Git artifact export and clean-instance replay | **NOT TESTED** | Stage B gated on Stage A |

## Codex CLI installation and execution evidence (operator output, 2026-10-22)

The owner provided these sanitized outputs from `lab-test`:

```text
PASS: codex-cli 0.163.0 (.../.local/share/ai-lab-experiments/codex/node_modules/@openai/codex/bin/codex.js)
For this shell: export PATH="$HOME/.local/bin:$PATH"
Authentication not checked. Start codex and sign in separately.
$ export PATH="$HOME/.local/bin:$PATH"
$ codex --version
codex-cli 0.163.0
```

**Acceptance:** user-local Codex binary installed and starts successfully: **PASS**, as reported by the operator. The complete npm installation transcript, exact Node/npm versions, auth status, and network connection to OpenAI have not been supplied. Treat **authentication and MCP discovery as unverified**.

## Codex authentication evidence (operator output, 2026-10-22)

The owner executed `codex login status` on `lab-test`:

```text
Logged in using ChatGPT
```

**Acceptance:** Codex CLI ChatGPT sign-in is confirmed by the operator's status output (**PASS**). No authentication token was shared. This does **not** establish n8n owner setup, instance-level MCP authorization, MCP tool discovery, or workflow execution.

## MCP discovery evidence (operator excerpt, 2026-10-22)

The owner supplied the following **partial** output from Codex tool discovery:

```text
t_workflow_best_practices
get_workflow_details
get_workflow_execution
get_workflow_history
get_workflow_sdk_reference
get_workflow_version
get_workflow_versions_diff
install_community_node
list_agent_versions
list_credentials
list_n8n_gateway_services
list_workflow_tags
mutate_agent
prepare_workflow_pin_data
publish_agent
publish_workflow
rename_data_table
rename_data_table_column
restore_workflow_version
revert_agent
```

**Interpretation:** Codex surfaced n8n-specific MCP tool names, indicating tool discovery. This is an excerpt, not the complete list; `t_workflow_best_practices` is truncated and its full name is not assumed. No successful invocation response from a read-only tool, verified tool schemas, actual workflow authoring tool, or execution output was included. Consequently **MCP tool discovery: PASS (operator excerpt)** and **MCP read call/authorization: PENDING**.

**Next evidence:** in Codex, call `get_workflow_sdk_reference` (or `get_workflow_best_practices` if actually discovered), summarize returned SDK/node types, and report whether the call returned valid server data or a tool error. Do not create/change/publish workflows until this succeeds.

## Next reproducible checks (on lab-test)

```bash
git rev-parse HEAD
codex --version
sudo docker image inspect docker.n8n.io/n8nio/n8n:2.44.5 --format '{{.Id}}'
bash experiments/workflow-automation-n8n/lab.sh verify
```

Do not display environment secrets, MCP bearer tokens, Docker `inspect` of container env or unsanitized logs.
Record the generated image ID, Codex version, and exact revision with subsequent Stage A results. The owner still needs to create the n8n owner account if not already configured, enable Instance-level MCP, and issue an **MCP API key** in the local UI. Codex sign-in is already confirmed.

**State boundary:** This is experiment evidence in a feature branch. It does **not** change accepted `main` project status, prove unattended provisioning, certify external network isolation, or validate the MCP workflow integration.
