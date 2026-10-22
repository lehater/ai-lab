# Optional developer tool — Codex CLI and Linux sandbox

**Proposal, not accepted or clean-VM verified.** This module is independent of the n8n experiment and is **not** part of default S0 → S1 → S1-D or the S2 Infrastructure Core. Intended baseline: Ubuntu 24.04 Desktop amd64/VMware after S0 networking, APT proxy and repository checkout.

## Why this module exists

The n8n experiment on `lab-test` encountered `bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted` with `kernel.apparmor_restrict_unprivileged_userns = 1`. Installing Ubuntu's **scoped** `bwrap-userns-restrict` AppArmor profile restored operation: `bwrap --unshare-user --unshare-net --ro-bind / / /bin/true` exited 0, and the **correct** Codex smoke command `codex sandbox -- /bin/true` exited 0. Interactive Codex shell commands also worked subsequently. These are **owner-reported observations on an existing configured VM**, not a test of this module from a clean snapshot.

The generalizable functionality is installation, version control and sandbox verification — **not** n8n MCP endpoints, workflow IDs, secrets or specific experiments.

## Commands — opt-in only

```bash
cd ~/projects/ai-lab
make codex-test      # offline/static checks: no privileged installation
make codex-setup     # optional host change: install pinned CLI and sandbox prerequisites
make codex-verify    # verify launcher/version, AppArmor restriction, bwrap, sandbox
```

The standalone entrypoint is `bash bootstrap/devtools/codex/setup.sh setup`; `verify` never downloads software. First setup may invoke `sudo apt-get` to install missing Node/npm, `bubblewrap`, and (only if needed) `apparmor-profiles`/`apparmor-utils`. The npm package `@openai/codex@0.163.0` is pinned in `setup.sh` for a reproducible starting point, not claimed to be the latest available version. npm traffic uses S0's local HTTP proxy on `127.0.0.1:10808`.

Fresh installations are user-local: `~/.local/share/ai-lab-devtools/codex` and `~/.local/bin/codex`. A valid previous `0.163.0` experiment-local symlink under `~/.local/share/ai-lab-experiments/codex` is **reused**, not overwritten or migrated. Unknown executables and versions are rejected to avoid destroying another Codex installation.

If `codex` is not on the current shell PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
codex --version
```

Persisting this PATH is an operator shell preference, not an automatic modification of `~/.profile`.

After setup, Codex sign-in is **operator-controlled**:

```bash
codex login
codex login status
```

Do not capture authentication output, `~/.codex/auth.json`, API keys or MCP tokens in Git. This module installs **no** MCP servers. Experiment-specific MCP lives with its consumer.

## Sandbox policy and verification

Codex's Linux sandbox relies on `bubblewrap`. On Ubuntu 24.04, AppArmor can block user namespace creation even if `bwrap` is installed. The module first tries:

```bash
codex sandbox -- /bin/true
```

If it fails **and** `kernel.apparmor_restrict_unprivileged_userns=1`, the optional setup installs and loads Ubuntu's packaged `bwrap-userns-restrict` profile (if no conflicting active attachment is observed), then retests. If the profile is absent or conflicts, setup **fails safely** for manual diagnosis. It never changes the global user namespace sysctl, disables AppArmor or invokes `--dangerously-bypass-approvals-and-sandbox`.

**Smoke acceptance**: on a clean prepared `lab-test`, after `make codex-setup` the standalone `make codex-verify` reports the pinned CLI, confirms the AppArmor restriction is still `1`, and confirms the sandboxed process exits `0`. Repeat setup and verify; test normal Codex read-only repo access inside an interactive session, without a privileged bypass request. Record actual command outputs/revision before requesting acceptance.

`~/.git/index.lock` can be protected by Codex's normal sandbox even when working-tree edits succeed. **This is separate from the AppArmor fix**. Use an operator-controlled Git commit/review workflow; do not loosen the sandbox or grant full `/var/run/docker.sock` access just to commit.

Documentation: [OpenAI Codex Linux sandbox](https://learn.chatgpt.com/docs/sandboxing); [Codex permissions](https://learn.chatgpt.com/docs/permissions).

## Which editor?

Codex CLI and the official VS Code Codex extension are **two interfaces to the Codex agent**, not two alternative Linux sandboxes. The extension has its own bundled runtime; do not force its `chatgpt.cliExecutable` to the npm executable. When CLI and IDE run on the **same machine/user**, they share the `~/.codex/config.toml` configuration layers (sandbox, approvals, MCP); editor-specific `chatgpt.*` settings are separate.

**Option A — simplest for validating the IDE:** Install official VS Code on the existing `lab-test` Ubuntu Desktop, then install the official **Codex** extension `OpenAI.chatgpt`, sign in to ChatGPT, open the repository, and run a read-only sandbox check. This avoids SSH server changes but consumes GUI resources on the VM. Editor installation is not included in `make codex-setup` and is not yet tested.

**Option B — recommended long-term workbench (conditional):** Run VS Code on the operator's Windows PC, use Microsoft **Remote - SSH** (`ms-vscode-remote.remote-ssh`) to connect to the Ubuntu VM, and install the Codex extension in the **SSH: lab-test** extension host, so project files and the agent execute in Ubuntu. Remote-SSH installs VS Code Server on the VM and requires an accessible SSH **server** there; the accepted S1 GitHub SSH setup currently configures only an **outbound SSH client**. Provisioning `sshd`, firewall/VM reachability and trust must be an explicit, separately reviewed optional feature, not an automatic consequence of installing Codex. Do not open SSH or VS Code services to the internet for this task.

For a first Remote-SSH test, connect and open `~/projects/ai-lab`, confirm Codex extension activation, `/status`, read-only repository command, current effective config, sandboxing, and MCP accessibility if a relevant service is running. Remote extension compatibility may vary with VS Code and extension versions; do not assume the CLI's existing login or success guarantees the remote extension works.

Sources: [VS Code Remote - SSH](https://code.visualstudio.com/docs/remote/ssh), [Codex extension](https://marketplace.visualstudio.com/items?itemName=OpenAI.chatgpt), [Codex IDE settings](https://learn.chatgpt.com/docs/ide/settings), [Codex configuration basics](https://learn.chatgpt.com/docs/config-file/config-basic). Related upstream Remote-SSH compatibility reports: [#32385](https://github.com/openai/codex/issues/32385), [#42663](https://github.com/openai/codex/issues/42663).

**UI choice is not a prerequisite for installing the CLI module.** No VS Code installation or Remote-SSH service is provisioned by this proposal.

## Cleanup, upgrades and limits

No automatic uninstall is provided: removing a user-local installation may affect existing Codex authentication/configuration, and removing an AppArmor profile can change access for other applications. Review host state before any explicit operator cleanup. The module does not remove previously installed Node/APT packages or change `~/.codex/config.toml`.

To update the pinned Codex version, review upstream release/security notes, adjust the pin in code and tests, verify on `lab-test`, and document accepted changes through a separate PR. The current installer deliberately **does not overwrite an existing version or unknown launcher**.

**Status:** proposal implemented as code in a branch, but the new installer, idempotent setup and clean-snapshot replay have not been performed by the owner. Do not report them as PASS or mark the default baseline changed.
