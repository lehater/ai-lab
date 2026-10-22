# Optional host role: ripgrep

Status: **PROPOSED / NOT VERIFIED on lab-test**.

This deliberately small role demonstrates the Ansible host-component contract
on Ubuntu 24.04 amd64. It uses only `ansible.builtin` and the distro's APT
repository, avoiding a third-party Galaxy role, key or external APT source.

- `present` (default): install pinned `ripgrep=14.1.0-1` (Ubuntu Noble)
  when absent and independently verify `rg --version`. Pre-existing unmanaged
  packages are verified but **not adopted** or changed to the pinned version;
  rerun should not change the package.
- `verify`: read-only check that the package and binary are available.
- `absent`: requires `ai_lab_ripgrep_allow_remove=true`. It removes the
  package **only** when AI Lab's root-owned marker indicates this role first
  installed it. Pre-existing operator packages are **not** adopted or removed.
- `--check --diff`: preview; does not create ownership markers. Check-mode
  predictions are not a replacement for actual E2E results.

Marker: `/var/lib/ai-lab/ansible/ripgrep.installed`. The directory may
remain after removal. Marker creation is deliberately not transactional with
the package-manager operation: interrupted installation may leave an installed
package without a marker, in which case removal refuses and needs operator
review. Likewise, if someone removes or replaces the marker, the role refuses
to uninstall. Avoid manually editing marker state.

This role **does not** install or manage Ansible itself, S0's APT/proxy, SSH,
Docker, Codex/AppArmor, other projects, or user data.

Package licensing/selection: Ubuntu `ripgrep` package; upstream
https://github.com/BurntSushi/ripgrep (MIT OR Unlicense). The license of
a separate optional component must always be reviewed on adoption.

Controller: pinned upstream-maintained `ansible-core==2.21.5` installed
into an isolated user-level pipx environment via
[`controller-setup.sh`](../../controller-setup.sh). Ubuntu 24.04's
`ansible-core 2.16.x` archive package has reached upstream EOL; this
candidate intentionally does not adopt it as the long-lived controller.
The role's exact `ripgrep=14.1.0-1` package remains separate from the
controller.

Run from `ansible/` using [the runbook](../../README.md) and its
[`tests/test-offline.sh`](../../tests/test-offline.sh) guard smoke.
