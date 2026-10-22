# Proposal — optional Codex developer workbench for AI Lab (2026-10-22)

**Status:** proposal, not an accepted architecture decision. **Target:** developer tooling after S0/S1, not S2 Infrastructure Core and not a required step of the lab's clean bootstrap.

## Problem

The n8n MCP spike (draft PR #11, still isolated) needed operator-installed Codex and exposed a general Ubuntu 24.04 sandbox failure. The repeatable finding applies beyond n8n: Codex could start, but local shell commands failed with `bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted`. The fix was not to disable security: the operator installed Ubuntu's dedicated `bwrap-userns-restrict` AppArmor profile, leaving `kernel.apparmor_restrict_unprivileged_userns=1`; then `bwrap ... /bin/true`, `codex sandbox -- /bin/true`, and a read-only command in interactive Codex passed.

An additional `codex sandbox linux /bin/true` check failed (exit 101) due to **incorrect CLI syntax** — `linux` was treated as a program name. The correct check is `codex sandbox -- /bin/true`. An earlier missing `~/.local/bin` entry in PATH caused exit 127. Both are packaging/operator-runbook issues, not new sandbox vulnerabilities.

Codex protected `.git/index.lock` as read-only in its working-tree sandbox even after the OS sandbox worked. **Do not solve this by opening up agent write access to Git internals or the Docker socket.** Review and commit changes through a separately authorized Git workflow/operator.

Evidence: [n8n PR #11](https://github.com/lehater/ai-lab/pull/11) and its [2026-10-22 Stage A report](https://github.com/lehater/ai-lab/blob/proposal/workflow-automation-mcp-spike/experiments/workflow-automation-n8n/evidence/2026-10-22-stage-a-operator-report.md). This is operator/agent-reported evidence on an existing VM, **not** a clean-snapshot test of the proposed generic module.

## UI choice and clipboard problem

**Operator preference (2026-10-22):** Codex CLI remains the principal agent interface. VS Code + Codex extension may be installed **locally inside the Ubuntu VM** as an optional graphical editor. No Windows VS Code, Remote-SSH or SSH-server proposal is needed.

The most significant current CLI usability issue is **clipboard propagation from Ubuntu VMware guest to Windows host**: selecting text in Codex sometimes leaves an older value in the Windows clipboard, whereas copy via a GNOME graphical editor works. The root cause is not yet proven. Linux PRIMARY (mouse selection) differs from CLIPBOARD (explicit copy); VMware/open-vm-tools also has documented Wayland integration limitations.

**Diagnosis before implementation:** first try Codex's **`/copy`** or **Ctrl+O** command for the last completed response (officially supported in Codex CLI); `/raw` or `/tui` → Scrollback also improves terminal selection. Then try terminal `Ctrl+Shift+C` or menu Copy on nonsecret Codex output, test immediate Windows Ctrl+V, and check `echo "$XDG_SESSION_TYPE"`. For Wayland, consider the available **Ubuntu on Xorg** login session as a reversible option, then retry the transfer. If already X11 or failure persists, inspect VMware Guest Isolation copy/paste and `open-vm-tools-desktop` state. See [host clipboard runbook](../../bootstrap/host/clipboard.md).

No global clipboard selection sync daemon, background watcher, third-party clipboard patches, disabling of VMware isolation or forced desktop switch should be committed before an observed minimal fix. The clipboard belongs to **host/desktop VM integration**, not the Codex CLI installation or sandbox.

| Component | Role | Status in this proposal |
| --- | --- | --- |
| Codex CLI | Optional agent tool with pinned install/sandbox checks | Candidate implementation |
| Ubuntu/VMware clipboard | Existing host desktop UX; diagnose PRIMARY/CLIPBOARD and Wayland/X11 | Runbook only; unresolved |
| VS Code + official Codex extension | Optional graphical interface **inside Ubuntu VM** | Evaluated; not auto-installed |
| Windows VS Code/Remote-SSH/SSHD | Not requested for this lab setup | Out of scope |

The Codex extension `OpenAI.chatgpt` has its own bundled executable; CLI and IDE can share user `~/.codex/config.toml` when running in the same Ubuntu account. The editor does not replace sandbox prerequisites.

## Proposed code boundary

- Implement `bootstrap/devtools/codex/setup.sh` as an **opt-in**, user-local pinned installer and security test, exporting `make codex-setup`, `make codex-verify`, `make codex-test`.
- Reuse an existing known experiment-local pinned Codex installation safely; do not overwrite unknown launcher paths or import n8n MCP tokens/config.
- Install only prerequisite Ubuntu packages and the targeted AppArmor profile if the sandbox test shows it is needed, preserving the global restriction.
- Document operator-owned ChatGPT login, guest ↔ host clipboard diagnosis, and **optional local Ubuntu VM** VS Code setup; neither editor nor SSH server is installed automatically.
- No required dependency from S0/S1/S1-D to Codex. No change to accepted Docker, networking, secrets or S2 runtime scope.

## Acceptance gate

1. Static CI for installer Bash syntax and non-bypass invariants.
2. On a **new clean-snapshot replay** after accepted S0/S1, run `make codex-setup` and `make codex-verify`; record command outputs, revision and versions. Run setup again.
3. AppArmor userns global restriction remains `1`; actual Codex sandbox command passes. Confirm no unsandboxed workaround and no Docker group changes.
4. Operator-controlled `codex login status` verifies authentication separately; browser proxy remains an explicit operator step.
5. In a separate operator clipboard check, demonstrate Ubuntu Codex output copying directly to Windows, or record the unresolved host-integration limitation; do not block Codex sandbox acceptance on VMware clipboard behavior.
6. If optional **local Ubuntu VS Code** is chosen, prove the extension starts on the VM, shares the intended config/MCP and can review a controlled Git diff without widening sandbox rights.
7. Only **after** results and security boundaries are reviewed may the owner accept/merge this optional module. Do not mark any S0/S1/S1-D milestone differently solely because this proposal exists.

**Scope stop:** Do not build a generalized AI runtime, harness, agent orchestrator or IDE automation system. This candidate solves repeatable installation and secure local execution of **one** developer tool.

## Primary public references

- [OpenAI Codex Linux sandbox](https://learn.chatgpt.com/docs/sandboxing) — Ubuntu 24.04 AppArmor remediation and Bubblewrap.
- [Codex IDE settings](https://learn.chatgpt.com/docs/ide/settings) and [shared config](https://learn.chatgpt.com/docs/config-file/config-basic) — CLI/IDE agent configuration and editor-specific options.
- [Codex extension](https://marketplace.visualstudio.com/items?itemName=OpenAI.chatgpt), [VS Code on Linux](https://code.visualstudio.com/docs/setup/linux).
- [GNOME clipboard selections](https://wiki.gnome.org/Initiatives/Wayland/PrimarySelection), [Broadcom VMware Wayland limitation](https://knowledge.broadcom.com/external/article/320995).
