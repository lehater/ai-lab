# S1 — Host Bootstrap: GitHub SSH over S0 proxy (accepted first slice)

**Непрерывный маршрут от USB до S1:** [bootstrap/README.md](../README.md).
Здесь — только подробности модуля, требования безопасности и проверки.

This module implements the **first accepted S1 slice (PR #5), not the full host milestone**.
Target: Ubuntu 24.04 Desktop/amd64 under VMware after verified S0. The
host SSH config is isolated at `~/.config/ai-lab/github-ssh.conf`, uses
`ssh.github.com:443` via S0's `127.0.0.1:10808` proxy and does not edit
`~/.ssh/config`, Git remotes or the proxy. S0 is still an independent USB
Shell installer, with its documented manual v2rayN first-launch step.

## Operator entry points

From the checked-out repository after completing S0:

```bash
make help
make host-setup
make github-setup
make github-verify
make host-verify
make host-test
```

- `make host-setup`: check S0 prerequisites, install `netcat-openbsd` and
  `make` if absent, write/check the isolated SSH config, verify proxied HTTPS.
- `make github-setup`: run `host-setup`, guide SSH key creation/reuse,
  display the **public** key, optionally copy it to the desktop clipboard,
  try to open https://github.com/settings/keys, and prompt for the
  authentication check after the owner has registered the key. An
  operator can type `skip` and run `make github-verify` later.
- `make github-verify`: show official fingerprint guidance, let the
  operator inspect the SSH server key on first connection, then perform
  an authenticated Git SSH operation with strict host-key checking.
- `make host-verify`: local config + proxied HTTPS (NOT SSH authentication).
- `make host-test`: mocked/offline Shell regression tests.

**If `make` is missing after S0**, first run:

```bash
bash bootstrap/host/bootstrap.sh
```

That command installs `make` using the existing S0 APT proxy; future
operations use `make`. It does not add Make as a requirement to S0.

## SSH key and GitHub account security

The guided setup uses the standard `~/.ssh/id_ed25519` key path to work
with OpenSSH defaults. It **reuses the existing pair without replacing it**.
If neither file exists, it asks before calling `ssh-keygen`, which prompts
for an optional passphrase. If only half of the pair exists or its path
is symlinked, setup refuses to overwrite it and requires manual review.

No private key is printed, copied, committed or uploaded. The operator
registers **only** `id_ed25519.pub` at the GitHub settings page using
**New SSH key → Authentication Key**. The browser must have its own working
proxy settings; S0 APT/curl proxy configuration alone does not configure
Firefox or another GUI browser. When the clipboard utility or browser
is unavailable, the terminal prints a fallback.

Before trusting an unknown `[ssh.github.com]:443` host key, compare the
displayed fingerprint with [GitHub's published fingerprints](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints).
The wizard **never bypasses host-key checking or enrolls credentials
without operator action**. GitHub `ssh -T` can exit 1 when login succeeded,
so `make github-verify` confirms success with `git ls-remote`.

If a passphrase-protected key cannot be used noninteractively, unlock it
in an authorized SSH agent or enter the passphrase in an interactive
session; never disable host-key checks. After reverting a VMware snapshot,
the old locally generated private key may disappear. Reuse it only from a
protected backup or generate/register a new key and revoke the obsolete
GitHub account entry.

## Git push via S1 SSH (optional, per repository)

S0 clones `ai-lab` through **HTTPS**. S1 configures a working SSH alias
`ai-lab-github` via `~/.config/ai-lab/github-ssh.conf` but deliberately
**does not change** Git `origin` or `~/.ssh/config`. Therefore a plain
`git push origin` can still try HTTPS even after `make github-verify`
has passed. This was observed when publishing experiment PR #11.

After `make github-verify` succeeds, an operator who wants SSH **only
for writes** in this checkout can explicitly configure:

```bash
cd ~/projects/ai-lab
git remote -v
git remote set-url --push origin ai-lab-github:lehater/ai-lab.git
git config --local core.sshCommand \
  "ssh -F $HOME/.config/ai-lab/github-ssh.conf -o StrictHostKeyChecking=yes"
git remote -v
# fetch retains S0 HTTPS; push targets S1 SSH alias
git push origin HEAD
```

This changes **local Git configuration only**; the `core.sshCommand` path
is specific to the Ubuntu operator home. Do not blindly apply it to
other computers/repositories or overwrite an operator's custom SSH
configuration without inspecting it. Before first use, keep strict
GitHub host-key verification; this does **not** enroll keys or bypass
authentication. If `origin` is already intentionally customized,
inspect it rather than forcing the URL above.

## Acceptance on clean lab-test

1. Return to the agreed `vmware-tools-ready` snapshot; run S0 from USB
   with its genuine private payload (never copy these files into Git).
2. Use the repository cloned from accepted `main` by S0; no PR branch switch is required.
3. Run `make host-setup` (or the one-time Shell entrypoint if Make is absent),
   then run it again; verify `make host-verify`.
4. Run `make github-setup`. Observe key generation/reuse, optional clipboard,
   link opening/fallback, owner-controlled GitHub registration, and real
   `make github-verify` success. Record browser proxy limitations if any.
5. Run `make host-test`; reboot and recheck local/SSH authentication.
6. Record the exact revision, commands, observed output, environment and
   residual limitations in `docs/project/state.md` before proposing merge.

Owner-tested S1 SSH setup and authenticated SSH checks passed on `lab-test`.
After restoring the `vmware-tools-ready` snapshot, the owner confirmed
successful S0 → S1 replay, proxy autostart without manually starting v2rayN,
and post-reboot `make host-verify` / `make github-verify` PASS. Both
`make host-test` offline regression tests also passed after the isolation
fix. This evidence is owner-reported; a complete recorded install transcript
and the GUI browser's actual page load are not independently available.
The first S1 SSH slice is accepted through [PR #5](https://github.com/lehater/ai-lab/pull/5),
but **the full S1 milestone remains IN PROGRESS**, and this is not an
Enterprise-grade claim.
