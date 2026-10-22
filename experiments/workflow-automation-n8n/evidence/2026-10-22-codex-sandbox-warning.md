# Codex Linux sandbox startup warning — lab-test, 2026-10-22

**Source:** operator screenshot of the Codex startup warning, from Ubuntu 24.04 `lab-test`.
**Codex CLI:** `0.163.0` (previously confirmed). **Status:** warning observed; impact not demonstrated. Experiment is not blocked by the warning alone.

## Observed warning (verbatim)

```text
Warnings · 1 of 1 · Startup

Codex's Linux sandbox uses bubblewrap and needs access to create user namespaces.

These warnings may reflect settings from when the background server started.
If you've already fixed them, use /daemon to restart it.
```

## Assessment and boundaries

- This warning concerns the **local Linux command-execution sandbox** (bubblewrap / unprivileged user namespaces), not MCP authentication.
- Earlier in the experiment, Codex successfully authenticated via ChatGPT and called n8n `search_workflows` through MCP, returning `{"data":[],"count":0}`. That does **not** prove that Codex's local shell sandbox can execute commands safely.
- Ubuntu 24.04 AppArmor user-namespace policy may cause the warning. There is also an upstream issue reporting an apparently misleading warning when outer bubblewrap isolation already works but a nested bubblewrap probe is denied. The current VM cause is **not diagnosed**.
- Do **not** turn off AppArmor, disable namespace restrictions globally, run Codex unsandboxed/root, or weaken approvals merely to suppress this warning. Do not apply an AppArmor profile blindly when existing profiles have not been inspected.
- Continue the n8n MCP experiment only while ordinary operations work. If the agent reports `Operation not permitted`, namespace/loopback errors, or inability to read the repo/run sandboxed commands, stop and diagnose the narrow failure without bypassing sandbox protections.

## Read-only diagnosis if the warning becomes blocking

From the **normal host terminal** (not inside a Codex sandbox):

```bash
command -v bwrap || true
sysctl kernel.unprivileged_userns_clone kernel.apparmor_restrict_unprivileged_userns
ls -l /etc/apparmor.d/bwrap-userns-restrict /usr/share/apparmor/extra-profiles/bwrap-userns-restrict 2>/dev/null || true
```

Do not change sysctl/AppArmor until results are examined. A functional, no-network shell action within the existing Codex sandbox can help distinguish a cosmetic warning from an actual sandbox failure; avoid a privileged or `--dangerously-bypass-approvals-and-sandbox` test.

## Public references (not proof about this VM)

- Official Codex sandboxing guide: https://learn.chatgpt.com/docs/sandboxing
- OpenAI Codex issue on possible false bubblewrap warning with working outer sandbox (Ubuntu 24.04): https://github.com/openai/codex/issues/48681
- Codex Linux sandbox design: https://github.com/openai/codex/blob/main/codex-rs/linux-sandbox/README.md

**Evidence scope:** this records only a startup warning, not a vulnerability, validated isolation failure, or completed remediation. Nothing was changed on `lab-test` by this documentation commit.
