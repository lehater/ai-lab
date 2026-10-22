# AI Lab — Ansible optional host components (first candidate)

**Status: PROPOSED / NOT VERIFIED on `lab-test`.**
This is a minimal S2-adjacent host-management slice, **not** a completed
Infrastructure Core milestone and not a replacement for the accepted
S0 → S1 → S1-D bootstrap.

## What this manages

- `ansible-core` (no AWX/server) runs locally in the Ubuntu 24.04 Desktop
  VMware guest. The operator installs ansible-core **after** the accepted
  bootstrap, from Ubuntu's own APT repository.
- A first optional, low-risk component: [ripgrep](roles/ripgrep/README.md).
  This role establishes a reusable *present → verify → absent* pattern.
- No third-party Galaxy content, Ubuntu PPA, extra API keys, Docker changes,
  workstation-wide policy changes, or extra background services.
- A future VS Code role can exercise signed third-party APT sources and
  graphical checks; Codex/AppArmor requires a separate security review.
  Neither is claimed to exist here.

Responsibility boundaries:

```text
accepted S0/S1/S1-D       → base Ubuntu/Git/proxy/Docker (unchanged)
ansible-core (local CLI)  → new host-managed optional tools
individual roles          → package + explicit verification / cleanup
Compose                   → independent application services (unchanged)
Dev Containers            → independent project workspaces (future)
```

## Prerequisites and first run

Use the **independent** `lab-test` VMware test clone/snapshot. Preserve a
working snapshot, do not modify the manually configured reference `lab`.
First reproduce the accepted S0/S1/S1-D path documented in
[`bootstrap/README.md`](../bootstrap/README.md).

Install ansible-core (requires access to the Ubuntu **universe** repository,
working S0 APT proxy, and normal Ubuntu package signatures). No new PPA or
vendor account is required. The Ubuntu 24.04 archive currently provides
ansible-core 2.16.x; record the **actual installed version** and review its
maintenance status before treating it as long-term pinned production tooling.
The example role **pins the Ubuntu Noble `ripgrep` package to `14.1.0-1`** from the official archive; the Ansible controller package remains unpinned in this first slice and must be recorded at acceptance. If the exact role version disappears from configured APT repositories, the role must fail rather than silently upgrade.

```sh
sudo apt-get update
sudo apt-get install --no-install-recommends ansible-core
ansible-playbook --version

cd ~/projects/ai-lab
git rev-parse HEAD
git branch --show-current
cd ansible

# Discovery and static validations (no package installation).
ansible-inventory --list
ansible-playbook playbooks/ripgrep.yml --list-hosts
ansible-playbook playbooks/ripgrep.yml --syntax-check

# Preview is useful but may have limitations for dependent tasks.
ansible-playbook playbooks/ripgrep.yml --check --diff --ask-become-pass

# Operator-approved actual install (modifies only ripgrep + own marker).
ansible-playbook playbooks/ripgrep.yml --ask-become-pass

# Rerun: expect no package/marker changes.
ansible-playbook playbooks/ripgrep.yml --ask-become-pass

# Read-only functional test.
ansible-playbook playbooks/ripgrep.yml -e ai_lab_ripgrep_action=verify
rg --version
```

`--ask-become-pass` prompts locally if the operator's sudo policy requires
a password. Do not commit the sudo password or use `-e` to pass credentials.
All privileged tasks use `become: true` individually, not globally.
`--check` **does not guarantee a complete no-side-effects preview** for
arbitrary future roles, and is not evidence of completed installation.
This first role uses builtin modules without external execution hooks.

## Explicit and safe uninstall

**Run only on the test VM, after confirming ownership and reviewing the
role.** There is no automatic uninstall when the role/playbook is deselected.

```sh
# Preview the action, inspect target/ownership first:
ansible-playbook playbooks/ripgrep.yml \
  -e ai_lab_ripgrep_action=absent \
  -e ai_lab_ripgrep_allow_remove=true \
  --check --diff --ask-become-pass

# Apply only with operator authorization:
ansible-playbook playbooks/ripgrep.yml \
  -e ai_lab_ripgrep_action=absent \
  -e ai_lab_ripgrep_allow_remove=true \
  --ask-become-pass

# A second uninstall should be a harmless no-op.
ansible-playbook playbooks/ripgrep.yml \
  -e ai_lab_ripgrep_action=absent \
  -e ai_lab_ripgrep_allow_remove=true \
  --ask-become-pass
```

If `ripgrep` was already installed before the role, the role leaves **its existing version unchanged**, verifies it, and does not create an ownership marker; such a package is deliberately outside AI Lab's management.\n\nThe role refuses to uninstall an already-installed `ripgrep` **without**
its AI Lab ownership marker. A failed or interrupted install can leave a
package without a marker; then manual inspection is required, **not**
automatic removal. The role never uses APT autoremove/purge, never removes
shared repositories, and does not delete the marker directory.

## Mandatory acceptance checks before claiming VERIFIED

| Case | Expected result | Status |
| --- | --- | --- |
| Fresh `lab-test` after S0/S1/S1-D | No changes to baseline; ansible-core install and local-only inventory succeed | **NOT RUN** |
| `--syntax-check` and `--check --diff` | Syntax valid; preview documents expected changes | **NOT RUN** |
| First `present` | Install ripgrep; create *only* role ownership marker; `rg --version` works | **NOT RUN** |
| Second `present` | No role-managed package or marker changes | **NOT RUN** |
| `verify` and reboot | Package and command persist, readable to operator | **NOT RUN** |
| `absent` without approval | Rejected before package deletion | **NOT RUN** |
| `absent` after this role installed package | Remove package, preserve unrelated APT packages, no `autoremove`; second run no-op | **NOT RUN** |
| Pre-existing `ripgrep`, **no** AI Lab marker | Install action does not claim ownership; cleanup refuses to remove it | **NOT RUN** |
| Absent package and absent marker | Repeated approved cleanup is a no-op | **NOT RUN** |
| Regression on existing S0/S1/S1-D | Existing `make host-verify`, `make github-verify`, `make docker-verify` still pass | **NOT RUN** |

For the pre-existing-package negative case use a **separate disposable
snapshot/clone**, or document that it was not tested. Do not intentionally
corrupt or remove a working host package just to simulate this case.

Save the Git SHA, `ansible-playbook --version`, installed APT package
versions, the state of `/var/lib/ai-lab/ansible/ripgrep.installed`,
commands/results, target snapshot and limitations in
[`docs/project/state.md`](../docs/project/state.md) via a PR. Redact
credentials, proxy secrets and machine-specific private files.

After acceptance, additional host options can use Ansible roles. Do not
infer that a role from Galaxy has the same license as ansible-core: inspect
each role's origin, version, license, dependencies, privileges and upkeep
before inclusion.

Official upstream references:

- https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/apt_module.html
- https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_checkmode.html
- https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_reuse_roles.html
- https://packages.ubuntu.com/noble/ansible-core\n- https://packages.ubuntu.com/noble/ripgrep
- https://github.com/BurntSushi/ripgrep
