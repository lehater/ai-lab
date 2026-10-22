# n8n MCP discovery and read-only call — lab-test, 2026-10-22

**Source:** operator-supplied Codex session transcript from `lab-test`.
**Branch:** `proposal/workflow-automation-mcp-spike` (draft PR #11; do not merge).
**Scope:** Stage A connection gate only. Workflow authoring, writes, execution, and replay have not been verified.

## Observed

1. Codex discovered **51 n8n MCP tools**, reported under prefix `mcp__n8n__`.
2. Codex called `n8n.search_workflows` with a read-only request. Codex reports the explicit call arguments as `{"limit":1}`.
3. Tool response:

```json
{"data":[],"count":0}
```

No workflows were found through this call. No workflow was created, modified, published, or executed during this connectivity check.

**Acceptance gate: PASS.** Discovery plus an actual server-side read call succeeded. This confirms the MCP link/authentication is usable for this read request; it does not certify write permissions, other tools, or production isolation.

## Observed MCP tool names (51; prefix omitted)

```text
add_data_table_column
add_data_table_rows
archive_workflow
call_agent
create_agent
create_data_table
create_workflow_from_code
delete_agent
delete_data_table_column
discover_agent_assets
execute_workflow
explore_node_resources
get_agent
get_agent_builder_reference
get_data_table_rows
get_node_types
get_workflow_best_practices
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
search_agents
search_data_tables
search_nodes
search_projects
search_workflow_executions
search_workflows
test_workflow
unpublish_agent
unpublish_workflow
update_agent_integration
update_workflow
validate_agent
validate_node_config
validate_workflow
verify_agent_mcp_server
```

The reported tool namespace prefix is `mcp__n8n__` even though the operator guide proposed a local config alias `ai_lab_n8n_spike`. The effective registered alias may differ. The Codex task should use whichever tools are **actually exposed in that session**, rather than assuming a particular namespace.

## Stage A next

- Read `get_workflow_sdk_reference`, `get_node_types`, and/or `get_workflow_best_practices` as necessary, following actual tool schemas.
- Create a credential-free, manually triggered workflow via `create_workflow_from_code`; validate with `validate_workflow`; execute and inspect actual output (expected numeric `value=8`).
- Modify **the same** workflow using `update_workflow`; revalidate and execute (expected numeric `value=12`).
- Do not publish a workflow or install community nodes. Stop on incompatible tool schemas instead of asserting a false PASS.
- Store sanitized evidence, execution IDs, source/definition artifact, and all manual interventions in the experimental branch.

## Remaining evidence gaps

Exact checkout commit SHA and image ID/digest were not present in the operator's transcript. n8n MCP write actions, workflow validation, execution and reconstruction remain **NOT TESTED**.

**Never record MCP tokens, ChatGPT credentials or `~/.codex/auth.json` in Git.**
