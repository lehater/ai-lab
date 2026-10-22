# Codex task — author a verifiable n8n workflow via MCP

> **Stage A partially executed on lab-test (2026-10-22). Do not blindly rerun this file from the beginning.**
> The workflow `0MfgOrrQXujdLHVM` already exists, and its first execution (ID `1`) returned numeric `value:8`.
> Attempting `setNodeParameter` with an indexed array path was rejected. The factor remains 2, and the workflow was not published.
> **Read [RECOVERY.md](RECOVERY.md) and [operator results](evidence/2026-10-22-stage-a-operator-report.md) first.**
> Only after the local Codex sandbox works again should the agent *resume* at the existing-workflow update.
> The current n8n SDK task contract is retained here as the original test specification, **not** a command to create a second workflow.


You are operating against a **disposable local n8n test instance** on lab-test, from Git branch `proposal/workflow-automation-mcp-spike`. **Do not modify or merge `main`. Do not alter the AI Lab S0/S1/S1-D bootstrap.** The purpose is to evaluate the authoring interface, not the business use case.

## Verified setup facts (owner evidence, 2026-10-22)

On `lab-test`, Codex CLI `0.163.0` is installed and authenticated with ChatGPT. The n8n service passes the local health check. **MCP connectivity and read are now PASS:** Codex discovered 51 n8n tools (prefix `mcp__n8n__`) and `search_workflows({"limit":1})` returned `{"data":[],"count":0}`.

Evidence: [n8n MCP connectivity](evidence/2026-10-22-n8n-mcp-connectivity.md). Do not repeat a full discovery request unnecessarily; check available tool schemas relevant to authoring. Do not infer the remote tool namespace from the config alias.

**The remaining goal is write + actual execution**, not MCP connectivity.

## Objective

Use only **official instance-level n8n MCP tools** for workflow authoring (no manual canvas edits). Demonstrate create → validate → execute → update → validate → execute on a single workflow.

## Boundaries

- Confirm MCP connection and discover actual supported tool names, schemas, SDK and node versions first. Do not invent tool inputs.
- Create one workflow with a **manual trigger**; constant input `value = 4`; simple built-in transformation by factor 2; expected JSON numeric `value = 8`.
- Do not depend on external APIs, email, filesystem, shell execution inside a node, credentials, paid models, timers, webhooks or public triggers.
- Avoid scheduled publication, and do not touch any workflow other than this experiment's workflow.
- Require write approvals in Codex. No keys or private data in tool outputs, files, commits or terminal logs.
- When tool capabilities differ from the documentation, capture the actual limitation and stop rather than claiming success.

## Phase 1: create and test

1. These tools are already confirmed **discoverable**: `get_workflow_sdk_reference`, `get_node_types`, `validate_workflow`, `create_workflow_from_code`, `update_workflow`, `test_workflow`, `execute_workflow`, `get_workflow_execution`. Read the actual SDK reference and invocation schemas (and node types when needed) before using them. Discovery does **not** yet prove each operation succeeds.
2. Assemble minimal workflow using only supported nodes and current SDK syntax; validate before creating.
3. Create workflow named `AI Lab MCP Spike - multiply`.
4. Execute with `execute_workflow` or `test_workflow` according to the **actual supported trigger and tool input schemas**; if pin data is required, use `prepare_workflow_pin_data`. Use `get_workflow_execution` to inspect actual data when needed. A validation response alone is insufficient. If a manual trigger is not supported, record the blocker and stop instead of silently introducing a webhook or publishing a workflow.
5. Verify that the final item contains numeric `value = 8`. Capture the workflow ID, execution ID, chosen execution method and final JSON.

## Phase 2: modify the same workflow

1. Change factor 2 → 3 **via MCP** on the **existing workflow ID `0MfgOrrQXujdLHVM`**, after reading its current node configuration. The attempted indexed `setNodeParameter` path `assignments.assignments[0].value` is unsupported: n8n uses JSON Pointer paths and does not support array indices. Use the documented `updateNodeParameters` operation, passing a complete, validated Set-node parameters object that preserves unrelated fields (e.g., `replace: true` with the full parameters derived from the actual node). Do not create a replacement workflow.
2. Revalidate, execute, inspect output, and assert numeric `value = 12`.
3. Preserve the initial and final workflow definition or SDK source as reviewable artifacts; do not store unrelated workflows, credentials or instance secrets.
4. If the tool cannot return complete workflow definition, record the limitation and possible official export alternative. Do not fabricate a portable artifact.

## What to report

- PASS/FAIL for each phase, actual numeric output and execution IDs.
- Git revision; n8n version and image ID/digest; Codex version; MCP tools and significant tool errors.
- Operator/manual actions needed; whether workflow can be reconstructed from files or is currently stateful only.
- Any security/connection/version issues and the next smallest correction.

**Do not run Stage B clean-volume deletion/recreation until Stage A evidence has been reviewed.**
