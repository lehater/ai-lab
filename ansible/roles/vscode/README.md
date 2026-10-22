# Optional VS Code role — candidate only

**Status: DRAFT / NOT VERIFIED on lab-test.** This role handles the official
Microsoft Visual Studio Code **binary distribution** on **Ubuntu 24.04 amd64**.
It does not install extensions, default-editor preferences or extra runtimes.

**Licensing (verified 2026-10-22):** Microsoft's VS Code binary is available
for development/test usage without an IDE fee but is licensed under Microsoft's
[product terms](https://code.visualstudio.com/license); the source
[Code - OSS](https://github.com/microsoft/vscode) is MIT. The **Microsoft
binary is NOT itself an OSI Open Source distribution**. No paid extension,
GitHub Copilot, hosted service or Microsoft account is a prerequisite for
this role. Check license again for any proposed redistribution/product use.

Microsoft documentation:
- [VS Code Debian/Ubuntu signed repository](https://code.visualstudio.com/docs/setup/linux)
- [Microsoft GPG key fingerprint](https://learn.microsoft.com/linux/packages)
  for `microsoft.asc`: `BC528686B50D79E339D3721CEB3E94ADBE1229CF`.
- Source: `https://packages.microsoft.com/repos/code` stable, amd64.

## Actions

- `prepare`: download `microsoft.asc` as ordinary user (operator's
  preconfigured proxy if necessary), inspect GPG fingerprint and *only then*
  write isolated root-owned key `/usr/share/keyrings/ai-lab-vscode.asc` and
  deb822 source `/etc/apt/sources.list.d/ai-lab-vscode.sources`.
  Refresh APT metadata. Stop on any conflict in these paths without the
  role's repository ownership marker. **Do not auto-run untrusted shell**.
- `present`: before first install, require an exact `code` package version
  from `apt-cache madison code`; install through APT, create a root-owned
  ownership marker only when `code` was absent. Pre-installed `code` remains
  untouched and unowned. Repeat installed package action should yield
  `changed=0` (without cache refresh) when already at specified version.
- `verify` (**default**): read-only `dpkg` facts and `code --version`;
  headless CLI check is **not** GUI startup validation.
- `absent`: needs `-e ai_lab_vscode_allow_remove=true` and exact
  root-owned package marker; performs `apt state=absent`, with
  `autoremove=false`, `purge=false`. Checks package absence. Repeated
  approved removal is a no-op. Without ownership, removal refuses.

**Non-transactional failure boundaries:** If APT install finishes but marker
creation is interrupted, the installed package is left **unowned** and the
role refuses to uninstall it automatically. Do not forge ownership markers.
An interrupted `prepare` may also leave its key/source without a marker;
this intentionally blocks automatic adoption until operator review.

**Repository cleanup is NOT automated** in this first slice: package removal
leaves only the dedicated AI Lab Microsoft source, public key, and repo
ownership marker in place. This is deliberate: we do not blindly remove
an APT source that might later be used by other Microsoft packages or
tampered with by another actor. Assess external dependencies and define a
separate reviewed cleanup procedure before claiming full host-state reset.
Any future extension should protect operator-managed VS Code preferences
and user workspace data.

## Operator-run acceptance on disposable lab-test clone

After accepted S0/S1/S1-D bootstrap and `ansible/controller-setup.sh`:

```bash
cd ~/projects/ai-lab
git fetch origin
git switch feat/s2-vscode-optional-host-role
git pull --ff-only origin feat/s2-vscode-optional-host-role
git rev-parse HEAD
cd ansible
bash tests/test-vscode-offline.sh

# Prepare official Microsoft APT source; this changes host APT config.
ansible-playbook playbooks/vscode.yml -e ai_lab_vscode_action=prepare --ask-become-pass
apt-cache madison code

# Choose exact candidate from above, e.g. by reading its printed version;
# replace CHOSEN_VERSION below (no default/latest).
ansible-playbook playbooks/vscode.yml -e ai_lab_vscode_action=present \
  -e 'ai_lab_vscode_apt_version=CHOSEN_VERSION' --ask-become-pass

# Repeat with identical version (should be changed=0), then verify:
ansible-playbook playbooks/vscode.yml -e ai_lab_vscode_action=present \
  -e 'ai_lab_vscode_apt_version=CHOSEN_VERSION' --ask-become-pass
ansible-playbook playbooks/vscode.yml -e ai_lab_vscode_action=verify
```

Manually launch the GUI in the GNOME desktop **only after** checking CLI
and `code --version` on a trusted operator session. Do not enable extensions,
telemetry policy changes or sync automatically. APT updates may independently
change `code` later; repeat `present` with the old exact version may need
repository snapshot and can fail. Record the resolved deb version and digest
and decide how to pin updates separately.

After savepoint/reboot and operator-approved removal:

```bash
ansible-playbook playbooks/vscode.yml -e ai_lab_vscode_action=absent \
  -e ai_lab_vscode_allow_remove=true --check --diff --ask-become-pass
ansible-playbook playbooks/vscode.yml -e ai_lab_vscode_action=absent \
  -e ai_lab_vscode_allow_remove=true --ask-become-pass
ansible-playbook playbooks/vscode.yml -e ai_lab_vscode_action=absent \
  -e ai_lab_vscode_allow_remove=true --ask-become-pass

dpkg-query -W -f='${Status}\n' code 2>/dev/null || true
sudo test ! -e /var/lib/ai-lab/ansible/vscode.installed
```

A separate disposable snapshot is needed to validate **pre-installed
operator-managed `code` is not adopted/uninstalled**. Also repeat
`make host-verify`, `make github-verify`, `make docker-verify`
to check previous bootstrap. Record exact VM revision, proxy/GUI
observations, `changed` counts, package version, marker state, and failures.
Do **not** merge based only on syntax verification.

**Security and cost:** Third-party APT source is **trust expansion**:
signed_by scopes only that repository's packages; a valid trusted signature
does not make arbitrary packages inherently safe. Microsoft controls updates,
and the binary EULA differs from the MIT upstream source. Using stock
Ansible builtins avoids a dependency on unreviewed Galaxy roles.
