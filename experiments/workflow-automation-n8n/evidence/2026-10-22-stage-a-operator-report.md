# Stage A partial execution — operator-provided Codex report (2026-10-22)

**Historical snapshot: PARTIAL PASS at the time of this report.** **Later result:** the operator/Codex reported completion of the same workflow (×3 → value 12; execution ID 2) and a passing sandbox smoke test. Those later claims appear in [PR #11](https://github.com/lehater/ai-lab/pull/11) and the [closeout summary](../CLOSEOUT.md); the four local JSON/README artifacts have not yet been independently reviewed or committed. The observations below remain the original chronological partial report; do not interpret its pending steps as current tasks. Evidence is an operator-quoted Codex execution report and ordinary terminal diagnostics from `lab-test`. Not independently re-executed by the GitHub-only assistant.

## Confirmed by agent report

| Gate | Result |
| --- | --- |
| n8n MCP connectivity and read | PASS previously recorded |
| Read SDK reference, best practices, node definitions | PASS, reported |
| Validate three node configs and SDK | PASS (`valid: true`), reported |
| Create `AI Lab MCP Spike - multiply` | PASS, workflow ID `0MfgOrrQXujdLHVM` |
| Execute multiplier ×2 | PASS, execution ID `1`, status `success`, input `{"value":4}`, output `{"value":8}` |
| After failed update, read current workflow | PASS: still factor 2, unchanged `versionId`, `active:false`, `activeVersionId:null` |
| Update same workflow to ×3 | FAIL — see exact error below |
| Execute multiplier ×3 | NOT ATTEMPTED; no execution ID, no result 12 |
| Export local evidence | UNKNOWN: `apply_patch` interrupted and partial writes not inspected |
| Persist and replay from Git | NOT ATTEMPTED |

### n8n update attempt error

```json
{
  "error": "Operation 0 failed: path 'assignments.assignments[0].value' is invalid or contains unsafe segments",
  "errorCode": "UNKNOWN_ERROR"
}
```

The `setNodeParameter` operation requires RFC 6901 JSON Pointer paths and **does not support array indices**. The attempted dot notation / index path is unsupported. The supported `updateNodeParameters` operation can replace/merge node parameters, including passing the **entire assignments array**, based on actual workflow node details. n8n documents atomic batches; the unchanged `versionId` agrees with a rejected update. **Do not claim that replacement works until tested.**

Reference: https://docs.n8n.io/connect/connect-to-n8n-mcp-server/mcp-server-tools-reference#updateworkflow

### Local Codex sandbox failure

First failing command inside sandbox:

```bash
pwd && git status --short --branch && git branch -a && git remote -v
```

Actual stderr / exit:

```text
bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted
exit 1
```

This was a sandbox setup failure, before any Git command ran. Codex requested a retry *without sandbox*; the operator denied that escalation. No further local mutations were authorized.

Read-only host diagnosis supplied:

```text
/usr/bin/bwrap
kernel.unprivileged_userns_clone = 1
kernel.apparmor_restrict_unprivileged_userns = 1
```

The two probed `bwrap-userns-restrict` profile file locations did not exist on `lab-test`. This matches a known Ubuntu 24.04 Codex/bubblewrap/AppArmor incompatibility. **AppArmor policy has not been changed or tested after remediation.**

Additional Docker command attempted by Codex without privilege:

```bash
docker image inspect docker.n8n.io/n8nio/n8n:2.44.5 --format '{{.Id}}'
```

Failed: `permission denied while trying to connect to the docker API at unix:///var/run/docker.sock`. This is not a Docker health failure: the operator's earlier `sudo docker` commands already worked. Do not add the Codex user to the `docker` group or grant Docker socket access for this experiment. The operator can separately use `sudo docker image inspect ...` in a normal terminal.

## Subsequent operator diagnostics — clean Git and AppArmor status (2026-10-22)

The operator ran the previously requested read-only checks in a normal `lab-test` terminal:

```text
$ git status --short --branch
## proposal/workflow-automation-mcp-spike...origin/proposal/workflow-automation-mcp-spike

$ ls -la experiments/workflow-automation-n8n/evidence/2026-10-22-stage-a/ 2>/dev/null || true
[no output]

$ sudo aa-status | grep -Ei 'bwrap|unprivileged_userns' || true
   unprivileged_userns
```

**Interpretation:** no tracked/untracked Git changes were reported in the ordinary working tree, and the expected Stage A evidence directory was not present. The filtered AppArmor status shows the generic `unprivileged_userns` profile, **not** a loaded named `bwrap` profile. This does not by itself prove that no differently named AppArmor profile attaches to `/usr/bin/bwrap`, and no AppArmor changes have yet been made.

**Next safe gate:** check `/etc/apparmor.d` for profiles attached to `/usr/bin/bwrap`; only if none conflict, install and load the official Ubuntu 24.04 `bwrap-userns-restrict` profile. Then run a system-`bwrap` namespace test and `codex sandbox -- /bin/true`, confirming the global AppArmor setting stays at `1`. Installation and test results are pending.

## Incomplete local artifacts / Git coordination

Codex intended to write under `evidence/2026-10-22-stage-a/`:

- `factor-2.sdk.js`
- `factor-3-candidate-NOT-APPLIED.sdk.js`
- `results.json`
- `tool-schemas.txt`
- `workflow-after-error.json`
- `workflow-initial.json`

The operator interrupted `apply_patch`. **Do not assume these files were all written or none were written.** Inspect `git status --short` and the paths in the normal host terminal before attempting `git pull` or committing. Review JSON and tool captures for credentials before pushing.

## AppArmor package installation report — 2026-10-22

The operator provided the APT output from `lab-test`:

- `sudo apt-get update` returned an error `Hash Sum mismatch` for `noble-updates/multiverse/dep11/Components-amd64.yml.xz` on `ru.archive.ubuntu.com`. The issue concerned one APT metadata file, and older indices were retained where necessary. A completely clean package-list refresh is **not** established.
- The subsequent `sudo apt-get install -y apparmor-profiles apparmor-utils` **completed successfully**: `apparmor` and `libapparmor1` upgraded to `4.0.1really4.0.1-0ubuntu0.24.04.9`; `apparmor-profiles`, `apparmor-utils`, `python3-apparmor` and `python3-libapparmor` installed.
- The input batch included `sudo install ... bwrap-userns-restrict` and `sudo apparmor_parser -r ...`, but their actual loaded-profile status and sandbox smoke output have **not** been submitted. Do not declare remediation PASS solely on a successful package install.

**Next validation:** inspect existence of `/etc/apparmor.d/bwrap-userns-restrict`, `sudo aa-status | grep -Ei 'bwrap|unprivileged_userns'`, the unchanged `sysctl kernel.apparmor_restrict_unprivileged_userns`, then host `bwrap --unshare-user --unshare-net --ro-bind / / /bin/true` and `codex sandbox -- /bin/true`. Capture exit codes; never disable AppArmor or bypass Codex sandbox to make the tests pass.

## AppArmor profile loaded and bwrap smoke PASS — 2026-10-22

Operator-supplied terminal output:

```text
Profile file: PASS
   bwrap
   unpriv_bwrap
   unprivileged_userns
kernel.apparmor_restrict_unprivileged_userns = 1
bwrap exit: 0
Command 'codex' not found, but can be installed with:
sudo snap install codex
Codex sandbox exit: 127
```

**Interpretation:** `/etc/apparmor.d/bwrap-userns-restrict` is present; `aa-status` shows `bwrap` and `unpriv_bwrap`; the global AppArmor userns restriction remains enabled; standalone `bwrap --unshare-user --unshare-net --ro-bind / / /bin/true` returns 0. This **passes the standalone Bubblewrap test**.

The initially recommended `codex sandbox linux /bin/true` was **not actually run**, since that shell could not resolve `codex` (exit 127). This historical command was later found to have incorrect syntax. Codex was earlier installed successfully to `~/.local/bin/codex`, whose parent directory may not be present on this fresh shell's `PATH`. **Do not install Snap Codex**; export `PATH="$HOME/.local/bin:$PATH"`, run `hash -r`, confirm `command -v codex` and `codex --version`, then retry the Codex-specific sandbox smoke test. Codex's sandbox recovery remains unverified until this last test succeeds.

## Codex found; previous smoke command syntax incorrect — 2026-10-22

With `PATH="$HOME/.local/bin:$PATH"`, the operator confirmed:

```text
/home/alex/.local/bin/codex
codex-cli 0.163.0

thread 'main' (2) panicked at linux-sandbox/src/linux_run_main.rs:1600:5:
Failed to execvp linux: No such file or directory (os error 2)
Codex sandbox exit: 101
```

This error came from **our incorrect smoke-test command**, `codex sandbox linux /bin/true`. The Codex CLI subcommand `sandbox` accepts an executable as `COMMAND...` with `--` delimiting options; thus it attempted to run a program named `linux`. **Exit 101 is not evidence of a user-namespace or AppArmor failure.**

**Correct test** (as documented by the Codex CLI Linux sandbox reference):

```bash
codex sandbox -- /bin/true
echo "Codex sandbox exit: $?"
```

Expected: exit `0`. Until this is reported, standalone `bwrap` is **PASS** but the Codex sandbox remains **NOT VERIFIED**. No new packages, AppArmor changes, Snap installation or unsandboxed Codex execution are warranted from the exit 101 result.

## Correct Codex sandbox smoke test — PASS (operator log, 2026-10-22)

The operator executed the corrected Codex CLI command:

```text
$ codex sandbox -- /bin/true
$ echo "Codex sandbox exit: $?"
Codex sandbox exit: 0
```

**Result:** **PASS** for the Codex **CLI sandbox smoke test** on `lab-test` using Codex CLI `0.163.0`. Unlike previous attempts, this test used the correct syntax and was executed by Codex; code `0` confirms sandboxed process startup and completion of `/bin/true`. The AppArmor/user-namespace setting remained `1` in the preceding standalone bwrap check.

**Remaining guard:** a full interactive Codex session has not yet run `pwd && git status --short --branch` inside its ordinary sandbox after this fix. Perform that read-only check (without approving unsandboxed retry) before resuming MCP mutation. No reinstall, global sysctl change, or Docker socket permission change is needed.

## Next acceptance sequence

1. Repair/test Codex sandbox while **retaining** AppArmor restrictions. See [RECOVERY.md](../RECOVERY.md).
2. Inspect local Git tree in the normal host terminal, preserving any partial evidence.
3. Read workflow `0MfgOrrQXujdLHVM` through MCP. Confirm name, factor 2, `active:false` and version before mutation.
4. Use `updateNodeParameters` with parameters **constructed from the actual current Set node config**, changing only the factor, and passing the complete assignments array / relevant parameter structure.
5. Inspect saved graph and version, execute again and require numeric `value:12`, with a distinct execution ID.
6. Preserve SDK/definitions and operator evidence. **Only then** consider the gated Stage B replay on a fresh n8n instance.

**Do not merge PR #11. Neither full Stage A nor Stage B has passed.**
