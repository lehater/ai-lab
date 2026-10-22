# Proposal — optional Codex developer workbench for AI Lab (2026-10-22)

**Status:** proposal, not an accepted architecture decision. **Target:** developer tooling after S0/S1, not S2 Infrastructure Core and not a required step of the lab's clean bootstrap.

## Problem

The n8n MCP spike (draft PR #11, still isolated) needed operator-installed Codex and exposed a general Ubuntu 24.04 sandbox failure. The repeatable finding applies beyond n8n: Codex could start, but local shell commands failed with `bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted`. The fix was not to disable security: the operator installed Ubuntu's dedicated `bwrap-userns-restrict` AppArmor profile, leaving `kernel.apparmor_restrict_unprivileged_userns=1`; then `bwrap ... /bin/true`, `codex sandbox -- /bin/true`, and a read-only command in interactive Codex passed.

An additional `codex sandbox linux /bin/true` check failed (exit 101) due to **incorrect CLI syntax** — `linux` was treated as a program name. The correct check is `codex sandbox -- /bin/true`. An earlier missing `~/.local/bin` entry in PATH caused exit 127. Both are packaging/operator-runbook issues, not new sandbox vulnerabilities.

Codex protected `.git/index.lock` as read-only in its working-tree sandbox even after the OS sandbox worked. **Do not solve this by opening up agent write access to Git internals or the Docker socket.** Review and commit changes through a separately authorized Git workflow/operator.

Evidence: [n8n PR #11](https://github.com/lehater/ai-lab/pull/11) and its [2026-10-22 Stage A report](https://github.com/lehater/ai-lab/blob/proposal/workflow-automation-mcp-spike/experiments/workflow-automation-n8n/evidence/2026-10-22-stage-a-operator-report.md). This is operator/agent-reported evidence on an existing VM, **not** a clean-snapshot test of the proposed generic module.

## Architecture options

| Option | Benefits | Costs / constraints | Proposed use |
| --- | --- | --- | --- |
| Codex CLI only | Small, scriptable, SSH/automation friendly, direct sandbox test | Console UI less convenient for browsing/review | **Opt-in underlying developer capability** |
| VS Code on Ubuntu Desktop VM + Codex extension | Fastest GUI trial, existing local VM access, no inbound SSH service | GUI resources in VM; editor adds packages and update lifecycle | **Initial IDE compatibility spike** |
| Windows VS Code + Remote-SSH to Ubuntu VM + Codex extension in SSH host | Comfortable host UI, source, runtime and sandbox remain on VM | Need separately managed `sshd`, network exposure assessment, VS Code Server/extension compatibility | **Preferred operator workbench if a scoped SSH path is approved** |
| Windows VS Code with Codex running locally | Easy Windows-only setup | Different OS/sandbox and runtime; VM's localhost MCP unavailable without explicit tunnel | Not a substitute for validating AI Lab's Linux runtime |

The Codex extension is `OpenAI.chatgpt`; Remote - SSH is `ms-vscode-remote.remote-ssh`. The CLI and IDE share Codex `config.toml` layers **when running for the same user on the same machine**, but the VS Code extension carries its own executable and also has editor-specific `chatgpt.*` settings. Do not set `chatgpt.cliExecutable` simply to force an IDE to reuse the independently pinned npm CLI; OpenAI marks it development-only.

**Remote-SSH correctness gate:** The accepted S1 module configures GitHub SSH client/outbound transport, **not** an SSH server on `lab-test`. Do not assert that Windows can already connect, and do not add an inbound listener automatically. Once the operator chooses the approach, scope a separate optional SSH-server/UI path, test guest↔host reachability, and verify the extension runs on the remote extension host. VS Code Remote-SSH compatibility bugs have been reported; verify rather than assuming the IDE is equivalent to a working CLI.

## Proposed code boundary

- Implement `bootstrap/devtools/codex/setup.sh` as an **opt-in**, user-local pinned installer and security test, exporting `make codex-setup`, `make codex-verify`, `make codex-test`.
- Reuse an existing known experiment-local pinned Codex installation safely; do not overwrite unknown launcher paths or import n8n MCP tokens/config.
- Install only prerequisite Ubuntu packages and the targeted AppArmor profile if the sandbox test shows it is needed, preserving the global restriction.
- Document operator-owned ChatGPT login and optional VS Code setup; **do not** automatically install VS Code or SSHD until the UI path has been chosen and a concrete acceptance test defined.
- No required dependency from S0/S1/S1-D to Codex. No change to accepted Docker, networking, secrets or S2 runtime scope.

## Acceptance gate

1. Static CI for installer Bash syntax and non-bypass invariants.
2. On a **new clean-snapshot replay** after accepted S0/S1, run `make codex-setup` and `make codex-verify`; record command outputs, revision and versions. Run setup again.
3. AppArmor userns global restriction remains `1`; actual Codex sandbox command passes. Confirm no unsandboxed workaround and no Docker group changes.
4. Operator-controlled `codex login status` verifies authentication separately; browser proxy remains an explicit operator step.
5. If VS Code is chosen, prove the extension starts, attaches to the intended Ubuntu workspace, accesses the correct config/MCP, and can review a controlled Git diff without widening sandbox rights.
6. Only **after** results and security boundaries are reviewed may the owner accept/merge this optional module. Do not mark any S0/S1/S1-D milestone differently solely because this proposal exists.

**Scope stop:** Do not build a generalized AI runtime, harness, agent orchestrator or IDE automation system. This candidate solves repeatable installation and secure local execution of **one** developer tool.

## Primary public references

- [OpenAI Codex Linux sandbox](https://learn.chatgpt.com/docs/sandboxing) — Ubuntu 24.04 AppArmor remediation and Bubblewrap.
- [Codex IDE settings](https://learn.chatgpt.com/docs/ide/settings) and [shared config](https://learn.chatgpt.com/docs/config-file/config-basic) — CLI/IDE agent configuration and editor-specific options.
- [Codex extension](https://marketplace.visualstudio.com/items?itemName=OpenAI.chatgpt), [VS Code Remote - SSH](https://code.visualstudio.com/docs/remote/ssh).
- Relevant upstream reports: [remote loading issue](https://github.com/openai/codex/issues/32385), [remote activation incompatibility](https://github.com/openai/codex/issues/42663).
