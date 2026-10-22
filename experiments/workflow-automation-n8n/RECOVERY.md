# Recover Stage A after Codex bubblewrap and n8n update errors

**Host:** `lab-test` Ubuntu 24.04; **branch:** `proposal/workflow-automation-mcp-spike`.
This is a *manual recovery procedure*, not verified setup automation. It changes **no** S0/S1/S1-D bootstrap or accepted project state.

## 0. Preserve local work first

The agent stopped after a sandbox failure and interrupted `apply_patch`. **Do not run `git pull`, `git reset --hard`, `git clean`, `git checkout`, or the n8n `lab.sh clean` on the VM yet.**

From a **normal terminal outside Codex**:

```bash
cd ~/projects/ai-lab
git status --short --branch
git status --short -- experiments/workflow-automation-n8n/evidence/
ls -la experiments/workflow-automation-n8n/evidence/2026-10-22-stage-a/ 2>/dev/null || true
```

These commands only inspect. Preserve any incomplete files without committing unreviewed `results.json` or `tool-schemas.txt`, which could contain private data.

## 1. Restore Codex's sandbox, not a privileged bypass

Observed in the failing VM:

```text
bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted
kernel.unprivileged_userns_clone = 1
kernel.apparmor_restrict_unprivileged_userns = 1
/usr/bin/bwrap exists
```

Ubuntu 24.04 restricts user namespaces under AppArmor. The **official Codex prerequisite** is an Ubuntu-packaged `bwrap-userns-restrict` profile. Unlike turning the global userns restriction off, it provides a scoped exception for Bubblewrap. Before installing it, check if an existing third-party profile already attaches to `/usr/bin/bwrap`; competing profiles can conflict.

### Preflight (read only; run outside Codex)

```bash
command -v bwrap
bwrap --version
sudo aa-status | grep -Ei 'bwrap|unprivileged_userns' || true
grep -RIl --include='*bwrap*' '/usr/bin/bwrap' /etc/apparmor.d/ 2>/dev/null || true
ls -l /etc/apparmor.d/bwrap-userns-restrict /usr/share/apparmor/extra-profiles/bwrap-userns-restrict 2>/dev/null || true
```

If `aa-status` shows a pre-existing bwrap/other-vendor attachment or you find competing profile files, **stop and inspect before proceeding**. Do not load a conflicting second profile blindly.

### Narrow official remediation (operator action)

If no conflicting attachment is present, install the Ubuntu profile using the system's existing APT settings:

```bash
sudo apt-get update
sudo apt-get install -y apparmor-profiles apparmor-utils
test -f /usr/share/apparmor/extra-profiles/bwrap-userns-restrict
sudo install -m 0644 \
  /usr/share/apparmor/extra-profiles/bwrap-userns-restrict \
  /etc/apparmor.d/bwrap-userns-restrict
sudo apparmor_parser -r /etc/apparmor.d/bwrap-userns-restrict
```

Do not disable AppArmor or set `kernel.apparmor_restrict_unprivileged_userns=0`. Recheck this value after installation:

```bash
sysctl kernel.apparmor_restrict_unprivileged_userns
# Expected: 1 (unchanged)
bwrap --unshare-net --ro-bind / / --proc /proc --dev /dev /bin/true
echo "bwrap exit code: $?"
export PATH="$HOME/.local/bin:$PATH"
hash -r
command -v codex
codex --version
codex sandbox linux /bin/true
echo "codex sandbox exit code: $?"
```

**Actual check so far (operator output, 2026-10-22):** profile file exists, `aa-status` reports `bwrap` and `unpriv_bwrap`, AppArmor restriction remains `1`, and standalone `bwrap` exits `0`. The Codex-specific check returned `127` **only because `codex` was not in this shell's PATH**. The commands above correct PATH before testing; they do not reinstall Codex or modify kernel settings. Confirm Codex sandbox exit `0` before marking recovery PASS.

If the CLI's sandbox subcommand syntax differs in `0.163.0`, inspect `codex sandbox --help` and adapt; do **not** disable sandboxing to make the test pass. Completely exit and restart Codex (or restart its daemon if applicable), then use a **read-only** repository command inside Codex, confirming no unsandboxed retry prompt.

Reference: https://learn.chatgpt.com/docs/sandboxing (Linux/WSL2 prerequisites). Caveat about bwrap profile collisions: https://github.com/openai/codex/issues/38715. Known identical error: https://github.com/openai/codex/issues/15057.

### Docker permission warning is separate

Do **not** give Codex direct access to `/var/run/docker.sock` or add the user to the Docker group. For the requested non-secret image identity, an operator can run from their normal shell:

```bash
sudo docker image inspect docker.n8n.io/n8nio/n8n:2.44.5 --format '{{.Id}}'
```

No Docker daemon access is needed for Codex to author n8n workflows via MCP.

## 2. Complete the same workflow through n8n MCP

Preserve the existing workflow: `0MfgOrrQXujdLHVM` named `AI Lab MCP Spike - multiply`. The initial result was numeric 8, execution ID 1. It was observed unarchived/active:false with factor 2 after a rejected update.

The rejected operation was `setNodeParameter` with path `assignments.assignments[0].value`. **Do not repeat it.** Official n8n `update_workflow` references specify:

- `setNodeParameter` paths are RFC 6901 JSON Pointers, not dot paths; **array indices are unsupported**.
- `updateNodeParameters` can deep-merge or replace a **full node parameters object**. Use it to set the **whole assignments array**.

Use the actual `get_workflow_details` response and actual discovered `update_workflow` schema. For a Set node with parameters similar to `{mode: 'manual', assignments: {assignments: [...]}, options: {...}}`, construct the **complete, validated updated parameters** with only the multiplier change. For safety prefer a single `updateNodeParameters` operation with `replace:true` and that full parameters object; preserve all other properties, node names, IDs and graph connections. Do **not** assume the placeholder shown here is the exact live parameters structure.

Confirm actual saved `versionId` and factor after updating. Do not publish, replace the workflow, use REST API to bypass MCP, or create another workflow. Then call supported `test_workflow`/`execute_workflow` and `get_workflow_execution`; assert numeric output 12.

n8n reference: https://docs.n8n.io/connect/connect-to-n8n-mcp-server/mcp-server-tools-reference#updateworkflow

## 3. Evidence and exit criteria

- **Sandbox PASS** only after a sandboxed read-only command executes normally without a bypass request.
- **Workflow Stage A PASS** only if n8n shows **the same workflow ID**, an actual changed draft, and a successful second execution with numeric `value=12`.
- Check the local evidence directory, redact secrets, capture tool error and corrected operation, then commit only sanitized artifacts **to this experimental branch**.
- Stage B export/replay remains blocked until the above is confirmed.

**Never merge to main.**
