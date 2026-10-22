# AI Lab — Ansible optional host components (first candidate)

**Status: PROPOSED / NOT VERIFIED on `lab-test`.**
This is a minimal S2-adjacent host-management slice, **not** a completed
Infrastructure Core milestone and not a replacement for the accepted
S0 → S1 → S1-D bootstrap.

## What this manages

- `ansible-core` (no AWX/server) runs locally in the Ubuntu 24.04 Desktop
  VMware guest. The operator installs ansible-core **after** the accepted
  bootstrap via the isolated user-level `pipx` environment and a pinned,
  currently upstream-maintained version. Only `pipx` comes from Ubuntu APT.
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

**Controller version and security.** Ubuntu 24.04 Noble `universe`
offers `ansible-core 2.16.3` [Ubuntu package], while Ansible upstream
ended maintenance of the 2.16 branch in **July 2025**. Using that package
as our future-proof 2026 management foundation would be a mistake.
Instead, we pin **`ansible-core==2.21.5`**, released **2026-10-05**, which
supports the Ubuntu 24.04 system Python **3.12** and is upstream-maintained
until November 2027. This is a deliberate version decision and will
need routine review before that date.

Install `pipx` and its dependencies **from signed Ubuntu APT**, then install
Ansible into an isolated **non-root pipx virtual environment** from PyPI.
No Ansible PPA, Ubuntu system-Python `pip --break-system-packages`,
commercial Red Hat AAP subscription, Galaxy collection or background
control plane is required. The first slice's
[`controller-setup.sh`](controller-setup.sh) only performs these steps.
It **does not** change S0's proxy settings or silently replace an existing,
different Ansible executable. Review the script before running it.

**Network precondition:** successful APT through the existing S0 proxy
does **not** imply PyPI works through `pipx`. If direct PyPI fails, configure
standard `HTTPS_PROXY`/`HTTP_PROXY` **for that operator shell** through an
already approved local S0 proxy endpoint, without committing proxy
credentials or changing system-wide networking. If no trusted PyPI access
is available, stop and record the blocked step; do not use `curl | bash`
or invent an alternate package mirror.

The example role **pins Ubuntu Noble `ripgrep=14.1.0-1`** from the
official archive. Missing or changed versions cause a visible error
rather than an automatic upgrade. Ansible's direct version is pinned;
transitive PyPI dependency versions are recorded with
`pipx runpip ansible-core freeze` during acceptance, not yet locked
by hashes in this first slice.

```sh
cd ~/projects/ai-lab
git rev-parse HEAD
git branch --show-current
cd ansible

# Controller install only: inspect this script before executing!
bash ./controller-setup.sh
export PATH="$HOME/.local/bin:$PATH"
~/.local/bin/ansible-playbook --version
pipx runpip ansible-core freeze

# Repeat setup: MUST detect the same version without replacing it.
bash ./controller-setup.sh

# Read-only smoke: syntax, localhost inventory, removal guards.
bash tests/test-offline.sh

# Discovery and static validations.
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

This is intentionally a **post-bootstrap** management tool: not required
to recover S0, and not evidence of S2 service/data/secret acceptance.

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

If `ripgrep` was already installed before the role, the role leaves **its existing version unchanged**, verifies it, and does not create an ownership marker; such a package is deliberately outside AI Lab's management.

The role refuses to uninstall an already-installed `ripgrep` **without**
its AI Lab ownership marker. A failed or interrupted install can leave a
package without a marker; then manual inspection is required, **not**
automatic removal. The role never uses APT autoremove/purge, never removes
shared repositories, and does not delete the marker directory.
**APT can install transitive dependencies** when satisfying the pinned package,
and a removal plan may reveal other dependency effects; inspect actual APT
output before approval. Disabling `autoremove` does **not** certify that
no other package could ever be affected. The marker protects the target
package from unintended removal, not all shared dependencies.

## Mandatory acceptance checks before claiming VERIFIED

| Case | Expected result | Status |
| --- | --- | --- |
| Fresh `lab-test` after S0/S1/S1-D | No changes to baseline; isolated pipx Ansible 2.21.5 install, repeat, exact version, dependency freeze and localhost inventory succeed | **NOT RUN** |
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
- https://packages.ubuntu.com/noble/ansible-core
- https://packages.ubuntu.com/noble/ripgrep
- https://docs.ansible.com/projects/ansible/latest/reference_appendices/release_and_maintenance.html
- https://docs.ansible.com/projects/ansible/latest/intro_installation.html
- https://pipx.pypa.io/latest/how-to/install-pipx.html
- https://forum.ansible.com/t/new-release-ansible-core-v2-21-5/46415
- https://github.com/BurntSushi/ripgrep
