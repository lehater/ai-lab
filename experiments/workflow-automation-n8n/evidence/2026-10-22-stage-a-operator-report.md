# Stage A partial execution — operator-provided Codex report (2026-10-22)

**Status: PARTIAL PASS, NOT COMPLETE.** Evidence is an operator-quoted Codex execution report and ordinary terminal diagnostics from `lab-test`. Not independently re-executed by the GitHub-only assistant.

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

## Incomplete local artifacts / Git coordination

Codex intended to write under `evidence/2026-10-22-stage-a/`:

- `factor-2.sdk.js`
- `factor-3-candidate-NOT-APPLIED.sdk.js`
- `results.json`
- `tool-schemas.txt`
- `workflow-after-error.json`
- `workflow-initial.json`

The operator interrupted `apply_patch`. **Do not assume these files were all written or none were written.** Inspect `git status --short` and the paths in the normal host terminal before attempting `git pull` or committing. Review JSON and tool captures for credentials before pushing.

## Next acceptance sequence

1. Repair/test Codex sandbox while **retaining** AppArmor restrictions. See [RECOVERY.md](../RECOVERY.md).
2. Inspect local Git tree in the normal host terminal, preserving any partial evidence.
3. Read workflow `0MfgOrrQXujdLHVM` through MCP. Confirm name, factor 2, `active:false` and version before mutation.
4. Use `updateNodeParameters` with parameters **constructed from the actual current Set node config**, changing only the factor, and passing the complete assignments array / relevant parameter structure.
5. Inspect saved graph and version, execute again and require numeric `value:12`, with a distinct execution ID.
6. Preserve SDK/definitions and operator evidence. **Only then** consider the gated Stage B replay on a fresh n8n instance.

**Do not merge PR #11. Neither full Stage A nor Stage B has passed.**
