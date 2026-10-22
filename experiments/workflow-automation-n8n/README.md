# n8n + Codex MCP — disposable experiment

**Latest status (2026-10-22): Stage A reported COMPLETE by operator/Codex, primary local artifacts NOT YET REVIEWED/COMMITTED.** The same workflow `0MfgOrrQXujdLHVM` returned `{"value":8}` (×2) then `{"value":12}` (×3), execution IDs 1 and 2, according to the operator report in [PR #11](https://github.com/lehater/ai-lab/pull/11). The correct `codex sandbox -- /bin/true` smoke test returned 0; interactive read-only sandbox operation was also reported successful. **Do not rerun workflow creation or assume clean-instance replay**. Exact primary evidence files are still local to `lab-test` and have not been independently reviewed. The actionable next step is the [safe closeout procedure](CLOSEOUT.md), **not** further Stage A or Stage B testing.

Previous partial failure and remediation are historical evidence in [Stage A report](evidence/2026-10-22-stage-a-operator-report.md) and [recovery guide](RECOVERY.md); they do not override the later operator-reported outcome. Branch static CI previously passed. This is **not** an accepted Infrastructure Core service or S3 module. All code belongs to experimental Draft PR #11; **no merge to main**.

## Purpose and responsibilities

- AI Lab S1-D Docker/Compose provisions and destroys a **temporary** n8n instance.
- **Codex CLI** authors and edits workflows through the n8n **instance-level MCP** endpoint.
- **n8n** runs/test-executes workflows independently from Codex.
- Git stores the Compose configuration and, **only after the real experiment**, sanitized workflow definitions/evidence.

This is a test of agent-driven **workflow authoring and reproducibility**, not an attempt to replace AI Lab bootstrap scripts, Make or CI with n8n.

## Closeout gate (2026-10-22)

Functional proof-of-concept was reported successful. **Four files under** `evidence/2026-10-22-stage-a/` **remain untracked on lab-test**, and `docs/project/state.md` had an unexpected local modification. Do not pull, switch branches, reset, delete the project, or run the original Codex workflow task before inspecting/preserving them.

See [CLOSEOUT.md](CLOSEOUT.md) for the one-block read-only audit, review, safe evidence capture and scoped cleanup requirements. [RECOVERY.md](RECOVERY.md) is a historical troubleshooting guide, not a request to repeat the completed experiment.

## Preconditions

- Work on `lab-test` (Ubuntu 24.04/VMware) with accepted S0 → S1 → S1-D already installed. Run Codex **inside the same VM** as n8n. Remote Codex execution cannot use this VM's `127.0.0.1` without separately authorized transport.
- Docker and Compose work; **Codex CLI is not part of the accepted lab-test baseline**. Install it separately using this experiment's user-local installer below, then log in as the operator. No existing Codex installation is assumed.
- A free local TCP port 5678. No shared production n8n instance.
- No real customer content, real credentials or public webhooks.
- n8n Docker tag is explicitly `2.44.5` for this experiment. Confirm image pull and record its **actual image ID/digest**; version pinning by tag alone does not guarantee identical bytes.

## Stage A: run a local disposable instance

From the experimental branch only:

```bash
cd ~/projects/ai-lab
git fetch origin
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

## Install Codex CLI on lab-test (experimental prerequisite)

The VM does **not** contain Codex as part of S0/S1/S1-D. This experiment provides a dedicated setup script. It is **not** a change to Infrastructure Core or permanent host bootstrap.

```bash
cd ~/projects/ai-lab
git fetch origin
git switch proposal/workflow-automation-mcp-spike
git pull --ff-only origin proposal/workflow-automation-mcp-spike

bash experiments/workflow-automation-n8n/codex-setup.sh install
bash experiments/workflow-automation-n8n/codex-setup.sh verify
export PATH="$HOME/.local/bin:$PATH"
codex --version
```

The script:

- Supports the tested Ubuntu 24.04 / x86_64 environment; installs **Node.js and npm from Ubuntu APT if missing**, reusing S0's existing APT proxy. This is an explicit **host package** change and is not undone by the n8n `lab.sh clean` command.
- Uses the official npm package `@openai/codex@0.163.0` (version pinned for this experiment), installing **without root** in `~/.local/share/ai-lab-experiments/codex/`.
- Sends the npm install traffic through S0's local Xray HTTP proxy at `127.0.0.1:10808`; refuses to replace another executable at `~/.local/bin/codex`.
- Performs a version/binary smoke check, but **does not authenticate** against OpenAI or prove the n8n MCP connection. An initial npm package download is required, even though Docker image pulls already passed.
- Can be re-run. It avoids a global `sudo npm install -g`. Other Node.js versions or existing Codex installations require separate review; the script fails rather than silently replacing them.

Next sign in interactively. The CLI supports signing in with the user's ChatGPT account (no API key is needed for that route). If Codex/OpenAI connectivity requires S0's proxy, enable it **in the shell where Codex runs**, while bypassing proxying for local n8n MCP:

```bash
export PATH="$HOME/.local/bin:$PATH"
export HTTP_PROXY=http://127.0.0.1:10808
export HTTPS_PROXY=http://127.0.0.1:10808
export NO_PROXY=127.0.0.1,localhost
codex login
codex login status
```

If interactive browser login is blocked, inspect `codex login --help` for available alternatives; do not send login tokens to a chat or commit credential files. Browser traffic may require its own proxy settings; shell proxy variables alone do not configure GNOME browsers. Avoid recording `~/.codex/auth.json` in Git.

**Operator-confirmed:** installation/binary check of Codex 0.163.0 and `codex login status` (`Logged in using ChatGPT`) are PASS on lab-test. Node/npm versions remain unrecorded; authentication tokens have not been shared.

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

**Original Stage A task (reported complete; for historical reference only):** From the experiment branch, Codex was tasked via [CODEX_TASK.md](CODEX_TASK.md). Do **not** rerun creation or mutation for closeout. The original minimal workflow:

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

`clean` removes only the named experimental Compose project's containers, networks, volume and local key file; it verifies no labeled objects remain. It does **not** delete other Docker resources, Git files, Codex settings, the separately installed experimental Codex CLI/Node/npm, or revoke an instance MCP token. Manually remove the `ai_lab_n8n_spike` Codex MCP entry when finished. **Do not run `docker system prune` / `docker volume prune`.**

## Verified vs unverified

Static CI passed. **Owner-observed** local n8n startup, Codex CLI login and MCP discovery/read passed on lab-test. **Workflow creation, edit and both executions are reported PASS by owner/Codex in PR #11; the complete raw evidence remains unreviewed and uncommitted.** Git-based export/replay on a clean n8n volume (Stage B) was **not attempted** and is not needed to close the limited functional hypothesis. Use [CLOSEOUT.md](CLOSEOUT.md) before removing data or closing PR #11; do not update accepted `main` project-state documents from this experiment.

## Sources

- [Official n8n MCP access](https://docs.n8n.io/connect/connect-to-n8n-mcp-server)
- [Official n8n MCP tools](https://docs.n8n.io/connect/connect-to-n8n-mcp-server/mcp-server-tools-reference)
- [Official n8n Codex connection examples](https://docs.n8n.io/connect/connect-to-n8n-mcp-server/mcp-client-examples)
- [Official Codex installation](https://github.com/openai/codex#readme)
- [Codex MCP configuration](https://developers.openai.com/codex/mcp)
- [n8n Docker Compose installation](https://docs.n8n.io/deploy/host-n8n/install-options/install-using-docker-compose)
