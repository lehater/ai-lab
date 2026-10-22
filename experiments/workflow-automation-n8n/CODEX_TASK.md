# Codex task — author a verifiable n8n workflow via MCP

You are operating against a **disposable local n8n test instance** on lab-test, from Git branch `proposal/workflow-automation-mcp-spike`. **Do not modify or merge `main`. Do not alter the AI Lab S0/S1/S1-D bootstrap.** The purpose is to evaluate the authoring interface, not the business use case.

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

1. Enumerate MCP tools; check for `get_workflow_sdk_reference`, `get_node_types`, `validate_workflow`, `create_workflow_from_code`, `test_workflow` and `execute_workflow` or their documented equivalents. Record names/versions.
2. Assemble minimal workflow using only supported nodes and current SDK syntax; validate before creating.
3. Create workflow named `AI Lab MCP Spike - multiply`.
4. Run through `execute_workflow` with manual mode, or `test_workflow` with correct pin data for the manual trigger; use `get_workflow_execution` to inspect actual data when needed. A validation response alone is insufficient.
5. Verify that the final item contains numeric `value = 8`. Capture the workflow ID, execution ID, chosen execution method and final JSON.

## Phase 2: modify the same workflow

1. Change factor 2 → 3 **via MCP**, preserving the workflow ID.
2. Revalidate, execute, inspect output, and assert numeric `value = 12`.
3. Preserve the initial and final workflow definition or SDK source as reviewable artifacts; do not store unrelated workflows, credentials or instance secrets.
4. If the tool cannot return complete workflow definition, record the limitation and possible official export alternative. Do not fabricate a portable artifact.

## What to report

- PASS/FAIL for each phase, actual numeric output and execution IDs.
- Git revision; n8n version and image ID/digest; Codex version; MCP tools and significant tool errors.
- Operator/manual actions needed; whether workflow can be reconstructed from files or is currently stateful only.
- Any security/connection/version issues and the next smallest correction.

**Do not run Stage B clean-volume deletion/recreation until Stage A evidence has been reviewed.**
