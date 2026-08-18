# n8n MCP Tool

## Purpose

Register the official n8n instance-level MCP server as an external tool surface for Atlas agents.

This repository stores the tool contract and configuration template. It does **not** store an n8n MCP token, endpoint secret, or live credentials.

## Canonical source

- n8n MCP server tools reference: https://docs.n8n.io/connect/connect-to-n8n-mcp-server/mcp-server-tools-reference
- n8n MCP server configuration is supplied by the target n8n instance.

## Primary tools

### Workflow discovery

- `search_workflows` — discover workflows by name/description and optional project/tags.
- `get_workflow_details` — retrieve workflow structure and trigger information.

### Workflow execution

- `execute_workflow` — execute a workflow by ID; returns an execution ID.
- `get_execution` — inspect an execution by workflow ID and execution ID.
- `search_executions` — discover executions and their status.

### Safe workflow testing

- `test_workflow` — test a workflow with pin data without relying on external services.
- `prepare_test_pin_data` — determine pin data required for a workflow test.

### Workflow construction / validation

- `get_sdk_reference` — retrieve the n8n Workflow SDK reference.
- `get_workflow_best_practices` — retrieve guidance for a workflow technique.
- `validate_workflow` — validate SDK workflow code before creation.
- `create_workflow_from_code` — create a workflow from validated SDK code.

## Atlas usage policy

For COS Domain Map / CCAMEL work, the preferred sequence is:

```text
search_workflows
      ↓
get_workflow_details
      ↓
search_executions
      ↓
get_execution
      ↓
OVR / evidence reconciliation
```

Do not infer current runtime materialization from the workflow registry alone.

Distinguish:

```text
CANONICAL REGISTRY
≠
REPOSITORY MATERIALIZATION
≠
N8N WORKFLOW MATERIALIZATION
≠
CURRENT EXECUTION EVIDENCE
```

For the current Domain Map investigation, this tool is particularly relevant to the chain:

```text
WF REGISTRY
   ↓
n8n MCP
   ↓
WORKFLOW DETAILS
   ↓
TRIGGER / CALLER
   ↓
EXECUTION HISTORY
   ↓
OVR GENERATION RELATION
```

No workflow should be executed merely to prove existence during an AS-IS photograph. Execution is a write/side-effect operation and requires an explicit authorized action.

## Versioning note

The available MCP tools depend on the n8n instance version and configuration. The repository must not claim a tool is available merely because it exists in the documentation; availability must be observed from the connected instance.
