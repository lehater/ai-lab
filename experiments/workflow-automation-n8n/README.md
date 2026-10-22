# n8n + Codex MCP — disposable experiment

**Status: EXPERIMENT PREPARED, NOT RUN ON `lab-test`.**
This is **not** an Infrastructure Core service, persistent AI platform, or a verified S3 module. All code belongs to branch `proposal/workflow-automation-mcp-spike` (draft PR #11); do not merge to `main`.

## Purpose and responsibilities

- AI Lab S1-D Docker/Compose provisions and destroys a **temporary** n8n instance.
- **Codex CLI** authors and edits workflows through the n8n **instance-level MCP** endpoint.
- **n8n** runs/test-executes workflows independently from Codex.
- Git stores the Compose configuration and, **only after the real experiment**, sanitized workflow definitions/evidence.

This is a test of agent-driven **workflow authoring and reproducibility**, not an attempt to replace AI Lab bootstrap scripts, Make or CI with n8n.

## Preconditions

- Work on `lab-test` (Ubuntu 24.04/VMware) with accepted S0 → S1 → S1-D already installed. Run Codex **inside the same VM** as n8n. Remote Codex execution cannot use this VM's `127.0.0.1` without separately authorized transport.
- Docker and Compose work; Codex CLI is already installed and logged in **by the operator**. This experiment does not install Codex.
- A free local TCP port 5678. No shared production n8n instance.
- No real customer content, real credentials or public webhooks.
- n8n Docker tag is explicitly `2.44.5` for this experiment. Confirm image pull and record its **actual image ID/digest**; version pinning by tag alone does not guarantee identical bytes.

## Stage A: run a local disposable instance

From the experimental branch only:

```bash
cd ~/projects/ai-lab
git switch proposal/workflow-automation-mcp-spike
git rev-parse HEAD
make docker-verify
bash experiments/workflow-automation-n8n/lab.sh static-test
bash experiments/workflow-automation-n8n/lab.sh up
bash experiments/workflow-automation-n8n/lab.sh verify
```

The first `up` generates a mode-600 `.env.local` with an n8n encryption key (**outside Git**) and creates one Compose project `ailab-n8n-mcp-spike` with a named data volume. The local UI is **http://127.0.0.1:5678/**.

Important: this is **HTTP with `N8N_SECURE_COOKIE=false` strictly for loopback-only testing**. Do not route or publish it to a LAN/Internet interface. If the local binding check fails, stop. Do not change the repository's existing Xray/Docker proxy settings (D-011).

Manually open n8n in the VM's browser, create the initial owner account, open **Settings → Instance-level MCP**, enable MCP access, and obtain an **instance-level MCP API key**. The separate **Settings → n8n API** key is not interchangeable. Never paste the key into Git or public logs.

## Configure Codex MCP (local-only, no token in config)

Add the following to **`~/.codex/config.toml`** on `lab-test`. Merge with existing settings, do not overwrite the whole file:

```toml
[mcp_servers.ai_lab_n8n_spike]
url = "http://127.0.0.1:5678/mcp-server/http"
bearer_token_env_var = "AI_LAB_N8N_MCP_TOKEN"
default_tools_approval_mode = "writes"
startup_timeout_sec = 20
tool_timeout_sec = 300
```

Supply the token only in the **shell that launches Codex**:

```bash
read -r -s -p 'Local n8n instance-level MCP token: ' AI_LAB_N8N_MCP_TOKEN
printf '\n'
export AI_LAB_N8N_MCP_TOKEN
codex mcp list
codex
```

Do not run `set -x` or echo the token. The variable is process-local; repeat after starting a new shell. Check the available MCP tools **inside a fresh Codex session** before proceeding. If the MCP endpoint returns 401, verify the instance-level token and the server URL copied from n8n; don't substitute the REST API key.

The approval mode above prompts for write operations. Keep approval enabled; the instance is isolated but workflow tools can still modify it.

## Codex authoring task

Feed Codex the source-controlled instructions in [CODEX_TASK.md](CODEX_TASK.md). The minimal workflow:

- Manual trigger
- Create a deterministic `value = 4`
- Transform it to `value = 8` (multiply by 2)
- Validate and execute via MCP; inspect real execution output
- Edit **the same workflow** to produce `value = 12` (multiply by 3)
- Validate and execute again; inspect real output
- Preserve workflow definition(s), versions, MCP tool names, execution IDs and any failure evidence

Prefer credential-free nodes. Use an existing built-in manual-execution tool or `test_workflow` with appropriate trigger pin data according to the **actual installed tool reference**. Do **not** publish or enable scheduled/public triggers.

**Stage A PASS:** both outputs match their specifications, updates were made by Codex over MCP (not by clicking nodes), no unintended external I/O and no published non-loopback port. A screenshot or validation result without execution output is not a pass.

## Evidence and Stage B gate

Record exact Git SHA, image ID/digest, `codex --version`, MCP tool count/names (never bearer values), timestamps, execution IDs, returned JSON for both versions, errors, manual interventions and test duration. Review evidence to remove credentials/private data before committing; `private/` and `unsanitized/` are Git-ignored.

**Only if Stage A passes**, export a workflow definition/SDK source that can be kept in Git. Recreate on a fresh project-owned volume and reconstruct from the artifact without canvas editing. Compare normalized workflow structure and test outputs; instance-generated IDs may differ. Record manual owner/MCP enrollment as a known prerequisite.

The CLI workflow export/import mechanism and version constraints must be confirmed on the **installed version** before executing Stage B. No success claim for persistence, export or replay is made by these files alone.

## Lifecycle / cleanup

```bash
bash experiments/workflow-automation-n8n/lab.sh ps
bash experiments/workflow-automation-n8n/lab.sh logs    # redact before sharing
bash experiments/workflow-automation-n8n/lab.sh stop    # volume kept
# When finished and after preserving needed evidence:
bash experiments/workflow-automation-n8n/lab.sh clean --destroy-experiment-data
```

`clean` removes only the named experimental Compose project's containers, networks, volume and local key file; it verifies no labeled objects remain. It does **not** delete other Docker resources, Git files, Codex settings or revoke an instance MCP token. Manually remove the `ai_lab_n8n_spike` Codex MCP entry when finished. **Do not run `docker system prune` / `docker volume prune`.**

## Verified vs unverified

Static review/quality checks may be performed without Docker. **Live setup, instance MCP access, Codex calls, the two workflow executions and clean-volume replay require running the commands on lab-test**. Record actual PASS/FAIL in the experiment branch. Do not update accepted `main` project-state documents from this experiment.

## Sources

- [Official n8n MCP access](https://docs.n8n.io/connect/connect-to-n8n-mcp-server)
- [Official n8n MCP tools](https://docs.n8n.io/connect/connect-to-n8n-mcp-server/mcp-server-tools-reference)
- [Official n8n Codex connection examples](https://docs.n8n.io/connect/connect-to-n8n-mcp-server/mcp-client-examples)
- [Codex MCP configuration](https://developers.openai.com/codex/mcp)
- [n8n Docker Compose installation](https://docs.n8n.io/deploy/host-n8n/install-options/install-using-docker-compose)
