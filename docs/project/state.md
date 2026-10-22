# Project state — AI Lab

**Updated:** 2026-10-22.  
**Authority:** accepted repository state is what has been merged into `main`;
this file is its human-readable status and handoff index.
It is **not** a substitute for code, tests, or evidence.

## Delivery status

**Long-term target, NOT a verified status:** Enterprise-grade, scenario-independent research infrastructure with repeatable IaC deployment, reusable modules/templates, appropriate security, observability and recovery. The checks below establish only their specific limited scope; Stage 0 still includes a documented manual operator step.

| Area | Status | Evidence / qualification |
| --- | --- | --- |
| S0: offline bootstrap, Ubuntu 24.04 Desktop / VMware | **VERIFIED MVP** | USB → offline v2rayN 7.20.2 install and configuration restore → HTTP/SOCKS5 proxy → APT → Git → public GitHub clone; owner repeated full clean-`lab-test` flow twice. [Merged PR #1](https://github.com/lehater/ai-lab/pull/1). |
| S0: subsequent-login GNOME autostart | **OWNER-VERIFIED ON `lab-test`** | After restoring `vmware-tools-ready` and repeating S0 → S1, owner explicitly confirmed v2rayN started without manual intervention after reboot; proxied HTTPS and authenticated Git SSH passed. Owner-reported verification recorded in [PR #5](https://github.com/lehater/ai-lab/pull/5). |
| S0: encryption and installer hardening | **DEFERRED** | Private proxy data is deliberately unencrypted for this functional MVP; physically protect storage; secrets stay out of Git. |
| S1: reproducible host bootstrap | **IN PROGRESS; FIRST SSH SLICE ACCEPTED ([PR #5](https://github.com/lehater/ai-lab/pull/5))** | After a clean VMware snapshot revert, owner confirmed successful S0 → S1 progression, rerunnable SSH config, GitHub SSH authentication, mocked tests and post-reboot Make checks. Detailed installation transcript not supplied; full S1 host provisioning remains outside this first slice. |
| S1-D: Docker/Compose Bootstrap | **FUNCTIONAL INTEGRATED REPLAY OWNER-VERIFIED on `lab-test`** | Owner explicitly confirmed restoring `vmware-tools-ready`, reinstalling S0 → S1 → S1-D from repository scripts, and providing the final PASS logs. Docker Engine 29.9.2, Compose v5.6.1, GitHub SSH, daemon proxy, image pulls and Compose lifecycle succeeded. Operator-assisted reproducibility on the specified VMware baseline; not unattended automation, external LAN isolation or package pinning. |
| S2 candidate: Ansible local optional host components | **ACCEPTED FIRST HOST LIFECYCLE SLICE; OWNER-TESTED ([PR #15](https://github.com/lehater/ai-lab/pull/15))** | On `lab-test` (2026-10-22), Ansible 2.21.5 controller/smoke PASS; `ripgrep 14.1.0-1` and owned marker observed; repeated `present` `changed=0`; `absent --check --diff` planned one removal; real `absent` removed package+marker, second `absent` `changed=0`; S1/Git SSH/S1-D Docker verification PASS. **Unmanaged pre-installed-package rejection and explicit after-reboot `rg` verification not evidenced**. This does not complete S2. |
| S2 optional Compose backup/restore fixture | **OWNER-TESTED FIRST INTEGRATION PASS ([PR #20](https://github.com/lehater/ai-lab/pull/20))** | Operator log on `lab-test` (2026-10-22): official `postgres:17` image pulled, primary service healthy, SQL row inserted, backup dump generated, a **separate new Compose project and named restore volume** created and healthy; restored data independently queried with `PASS: backup restored and independently read in separate fresh volume.` Only restore container/volume/network removed; original DB and local dump retained. **Exact Git commit in operator log, image digest, primary teardown and clean-VM repeat NOT evidenced.** This is scoped integration evidence, not a production backup system or full S2 acceptance. |
| AI platform / model runtime | **NOT STARTED AS REPRODUCIBLE DEPLOYMENT** | No platform deployment code is present in `main` at this checkpoint. |
| Applications / experiments | **NOT STARTED IN THIS REPOSITORY** | No runnable end-to-end AI application committed yet. |

## Stateful Compose fixture — scoped operator-reported recovery evidence (PR #20)

**Environment:** `alex@lab-test`, 2026-10-22, terminal log supplied by operator. The log contains the terminal output of `bash pilot.sh test` (the preceding exact Git checkout SHA, `bash -n` and `init` outputs were not supplied in this excerpt). No claim of assistant-side execution.

- `postgres:17` image was pulled and primary Compose project `ai-lab-s2-pg-pilot` created its `primary_data` named volume. The primary PostgreSQL container reported **Healthy**.
- SQL statements `CREATE TABLE` and `INSERT 0 1` succeeded. The script reported a locally retained dump in gitignored `private/backups/`; no dump bytes/passwords were shared.
- The separate recovery project `ai-lab-s2-pg-pilot-restore-5038` created a distinct `restore_data` named volume and a Healthy PostgreSQL container.
- Script reported **`PASS: backup restored and independently read in separate fresh volume.`** This validates the selected known-row `pg_dump` → `pg_restore` integration in a fresh database, not generalized PostgreSQL recovery guarantees.
- `docker compose down` for the restore project removed its container, named restore volume and network. Primary DB, its named volume and local backup **remained**. Primary cleanup (`AI_LAB_ALLOW_PILOT_TEARDOWN=YES`) was **not run** in this evidence.
- **Limitations:** moving image tag `postgres:17` (digest not reported), checkout SHA absent from submitted log, no claimed LAN exposure audit, no off-VM/production secret handling, restore durability guarantees, disaster recovery or complete S2 certification.

## Accepted Ansible host-management first slice — scoped evidence (PR #15)

This is an **accepted implementation slice** merged in [PR #15](https://github.com/lehater/ai-lab/pull/15), with owner-reported evidence limited to the recorded host component lifecycle. **D-012** adopts local Ansible Core for new optional host-managed tools; this is not whole-S2 acceptance.
Ansible Core was preferred after the exploratory comparison in
[merged PR #14](https://github.com/lehater/ai-lab/pull/14); this PR contains
a local inventory, a guarded `pipx` controller setup pinned to **ansible-core 2.21.5** (upstream supported, unlike Ubuntu Noble's 2.16.x archive package), one reusable role, a read-only negative-guard smoke and an E2E plan. **Controller setup, smoke, observed installation state, rerun idempotence, removal preview, **actual removal** and the existing S1/S1-D regression checks have owner-reported `lab-test` evidence.** The pre-existing unmanaged-package negative case and explicit post-reboot `ripgrep` verification are not evidenced.
The role manages only `ripgrep` and protects pre-existing packages from
automatic removal using a root-owned role marker. No Galaxy packages,
VS Code, Codex sandbox policies, daemon modifications or external cloud
services are installed by this change. S0/S1/S1-D accepted baselines and
the S2 service/persistent-data gate remain unaffected.

**Open acceptance on independent `lab-test`:** Ansible controller setup and verification require PyPI access via the operator's existing trusted proxy; this is not implied by S0 APT connectivity. A failed download is a BLOCKED step rather than a reason to adopt unmaintained Ansible 2.16. Use the operator procedure
in [`ansible/README.md`](../../ansible/README.md), perform syntax and
preview checks, first and repeated install, functional `rg --version`,
reboot, removal with explicit approval, repeated cleanup, a negative test
for pre-installed `ripgrep` from a disposable clone, and run regression
checks for existing `make host-verify`/`make github-verify`/
`make docker-verify`. Preserve factual PASS/FAIL output, versions, Git
SHA, snapshot/clone identity, manual actions and limitations **before merge**.
**Partial owner-reported evidence, 2026-10-22, `alex@lab-test`:**
- `bash controller-setup.sh` installed `ansible-core 2.21.5` in a user-level pipx environment using **Python 3.12.3**; printed `Controller bootstrap: READY (ansible-playbook [core 2.21.5])`.
- `bash tests/test-offline.sh` printed `Inventory localhost: PASS`, `playbook: /home/alex/projects/ai-lab/ansible/playbooks/ripgrep.yml` and `PASS: syntax, localhost-only inventory and default removal refusal.`
- This established **controller-install and limited static/negative-guard smoke success**; later evidence below also confirms installed `ripgrep` state and idempotent rerun. Post-reboot `ripgrep` verification, pre-existing-package negative case and S2 completion remain unverified; later evidence below confirms actual removal.
- The supplied excerpt does **not** show `git rev-parse HEAD`, the source snapshot/clone baseline, a repeated controller install, package version/dependency freeze or actual role apply. Preserve those gaps as open.

**Additional owner-reported check-mode evidence, 2026-10-22, `alex@lab-test`:**
- The immediately preceding operator command log showed a clean checkout `feat/s2-ansible-host-options-first-slice` at `d3f4598`, then an origin fast-forward to `6fa520e`. The following `--check --diff` ran on that branch; no standalone `git rev-parse HEAD` output was captured after pull.
- `ansible-playbook playbooks/ripgrep.yml --check --diff --ask-become-pass` completed: `ok=5 changed=1 unreachable=0 failed=0 skipped=20`. Apt predicted **one new package (`ripgrep`), zero upgrades and removals**, plus 43 unrelated available upgrades not applied. Role-owned marker creation and real executable verification were **skipped** in check mode.
- This is **PREVIEW PASS ONLY**, not a real package installation, marker creation, lifecycle acceptance, package upgrade or S2 acceptance. The dry-run emitted **three deprecation warnings** because the platform guard read injected top-level system facts. The branch was then patched to use `ansible_facts['distribution']`, `ansible_facts['distribution_version']` and `ansible_facts['architecture']`; **the patch itself is not yet retested on `lab-test`**.


**Additional owner-reported role lifecycle evidence, 2026-10-22, `alex@lab-test`:**
- Exact working tree revision at start of submitted log: `a8f443eab6720ed84a8bc4d0f9f0d6046c453b1d`. No modified-working-tree diff was supplied.
- `dpkg-query -W -f='${Status} ${Version}\\n' ripgrep` returned `install ok installed 14.1.0-1`; independent `rg --version` returned `ripgrep 14.1.0`. Root-owned `/var/lib/ai-lab/ansible/ripgrep.installed` existed and its content was `ai-lab-ripgrep-ownership-v1` (no trailing newline). This proves **observed installed state and marker**, not a separately retained transcript of the first `present` invocation.
- Repeated `ansible-playbook playbooks/ripgrep.yml --ask-become-pass` succeeded with `ok=10 changed=0 failed=0 skipped=15`. The platform guard using explicit `ansible_facts[...]` succeeded without the earlier deprecation warnings in this log.
- `ansible-playbook playbooks/ripgrep.yml -e ai_lab_ripgrep_action=absent -e ai_lab_ripgrep_allow_remove=true --check --diff --ask-become-pass` completed with `ok=10 changed=1 failed=0 skipped=15`. APT predicted **0 upgrades, 0 installations, exactly 1 removal (`ripgrep`)**. Ownership and approval assertions passed; marker deletion and installed-state verification were correctly skipped during dry-run.
- **At this earlier check-mode stage, no actual removal was run** in that log; a later operator log, recorded below, provides actual removal evidence.

**Owner-reported end-to-end teardown and baseline regression, 2026-10-22, `alex@lab-test`:**
- The new terminal excerpt starts with **`S1 local config and proxied HTTPS: PASS`**, authenticated Git SSH `PASS`, and **`S1-D Docker host and daemon proxy: PASS`**, with Docker Engine **29.9.2** and Compose **v5.6.1**. This supports regression of existing host/Git transport/Docker checks; it does **not** claim image pull, container network verification or outside-LAN isolation.
- With explicit `ai_lab_ripgrep_action=absent` and `ai_lab_ripgrep_allow_remove=true`, actual `ansible-playbook` reported root-owned marker/content assertions PASS, `Remove only role-owned ripgrep`: `changed`, `Remove ownership marker`: `changed`, and post-removal package-facts/absence assertion PASS. Recap **`ok=13 changed=2 failed=0 unreachable=0`**. Thus the role's **actual removal of one package and its own marker** passed.
- Repeating approved removal reported **`ok=8 changed=0 failed=0 unreachable=0`**. Independent `sudo test ! -e /var/lib/ai-lab/ansible/ripgrep.installed` printed **`Ownership marker removed: PASS`**. The `dpkg-query` line produced no installed-package status; Ansible's refreshed package-facts assertion is stronger evidence of absent package.
- **Not shown:** exact `git rev-parse HEAD` for this last log, an explicit `rg` verification between reboot and teardown (the earlier transcript covered `rg --version` before teardown), transcript of the `sudo reboot` command itself, independent negative test of a pre-existing unmanaged `ripgrep`, controller setup rerun, and pipx dependency freeze. Treat reboot persistence and unmanaged-package negative test as **OPEN**, not PASS.
- This evidence supports a **first host-managed optional-component lifecycle slice**, but **does not fulfil** the full S2 persistence/secrets/service-health gate. This first slice was subsequently merged to `main` in PR #15; untested cases remain open.

## First S1 GitHub SSH slice — owner-reported validation (accepted via PR #5)

Owner-reported console evidence on `lab-test`, 2026-10-21, for [PR #5](https://github.com/lehater/ai-lab/pull/5):

- Fetched `feat/s1-host-ssh-transport` through S0 HTTP proxy; checked out branch.
- Ran `bash bootstrap/host/bootstrap.sh` twice: first created `~/.config/ai-lab/github-ssh.conf`, second reported existing configuration already matched. Each run reported `S1 local config and proxied HTTPS: PASS`.
- Registered a newly created SSH public key in GitHub via owner action; ran `ssh -F ~/.config/ai-lab/github-ssh.conf -T ai-lab-github`. GitHub replied `Hi lehater! You've successfully authenticated`.
- Observed server Ed25519 fingerprint `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`; it matches the [published GitHub Ed25519 host fingerprint](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints).
- `bash bootstrap/host/verify.sh --auth` reported `S1 GitHub SSH authentication: PASS`.

- After the requested reboot, owner reported `bash bootstrap/host/verify.sh --local` with `S1 local config and proxied HTTPS: PASS`, and `bash bootstrap/host/verify.sh --auth` with `S1 GitHub SSH authentication: PASS`. This verifies **post-reboot SSH configuration, proxied HTTPS and authenticated Git transport** under the observed session. The log alone does not show whether the proxy started without user intervention.

- Owner ran `bash bootstrap/host/tests/test-configure.sh` on `lab-test`; output: `PASS: shell syntax, mocked config rendering, idempotency, safe conflict refusal.` This is an offline/mocked regression check, not a live network or new-clean-machine provisioning test.

- Follow-up code update in PR #5 added root Makefile tasks, an
  operator-guided SSH key setup, GitHub settings browser launch/fallback,
  and offline regression tests. Local mocked wizard tests passed outside
  `lab-test` (reuse, no overwrite, clipboard/browser actions and refusal
  of incomplete/symlink key paths). Earlier S1 configuration evidence refers
  to the preceding revision, not proof of this new Make/wizard workflow.
- Owner then ran the revised guided GitHub setup on `lab-test` (2026-10-21,
  partial console output provided). Wizard reported `Clipboard tool
  unavailable` (non-fatal), printed `https://github.com/settings/keys`,
  and reported that it sent the URL to the desktop browser; successful
  opening/loading of that page was not independently observed. Owner
  continued after GitHub key-registration prompt. Live SSH response:
  `Hi lehater! You've successfully authenticated`; proxied HTTPS PASS,
  authenticated Git SSH check PASS. This verifies the **revised wizard's
  interactive existing-key authentication path**, not first-time key creation,
  clipboard integration, or a clean-snapshot deployment.
- No complete S0→S1 installation trace after a clean reset has been provided yet.

- Owner ran `make host-test` on `lab-test` for the revised Make workflow:
  `test-configure.sh` passed, but `test-github-setup.sh` unexpectedly
  inherited an interactive terminal, prompted for live GitHub verification,
  then failed `ERROR: run make host-setup first` in its deliberately
  isolated temporary HOME. **This was an offline test isolation defect,
  not evidence of a broken host SSH setup.**
- Fix committed in PR #5: all mock wizard invocations in
  `test-github-setup.sh` explicitly use `</dev/null`, preventing TTY
  prompts and live network checks. On a separate local test environment,
  running the corrected `make host-test` under a pseudo-TTY as a
  non-root user produced both `PASS` lines (Shell/config/idempotency and
  mocked wizard preservation/browser/clipboard checks). Owner subsequently
  reran `make host-test` on `lab-test` and reported both expected PASS lines:
  `shell syntax, mocked config rendering, idempotency, safe conflict refusal`
  and `SSH wizard reuse, clipboard/browser guidance, no overwrite,
  incomplete/symlink protection, interactive opt-in`. This establishes
  regression success on that machine (the mock test does not prove GUI
  clipboard/browser behavior or a clean-snapshot S0→S1 run).

- Owner reported reverting `lab-test` to the known `vmware-tools-ready`
  VMware snapshot, then followed the S0 → S1 test instructions. The final
  post-reboot log shows `make host-verify` with
  `S1 local config and proxied HTTPS: PASS`; `make github-verify`
  showed `Hi lehater! You've successfully authenticated`, followed by
  another local HTTPS PASS and `S1 GitHub SSH authentication: PASS`.
  This confirms the target end-state on the recovered VM and working
  post-reboot SSH transport. The full S0/S1 installation output,
  current checked-out revision, and absence of manual proxy startup
  were not supplied in that log; these remain to be confirmed before
  certifying the whole replay.

- Owner explicitly confirmed after the `vmware-tools-ready` reset
  that the S0 bootstrap and first S1 SSH slice completed without errors and **v2rayN autostarted
  after reboot without manual intervention**. Together with the posted
  post-reboot `make host-verify` and `make github-verify` PASS logs,
  this supports the S0 autostart and first S1 SSH slice acceptance paths.
  The full installation transcript was not provided; distinguish
  owner attestation from complete retained machine evidence.
- Operator documentation gap found during replay: commands and their order
  still depended on reading a chat. PR #5 adds `bootstrap/README.md`
  as the single end-to-end USB-carried S0 → S1 runbook, with links from
  stage-specific and repository READMEs. Owner confirmed the physical USB
  was updated with the candidate runbook before merge; the final accepted
  revision will require a new copy to bring the on-disk guide up to date.

**Limits:** owner confirmed full clean-snapshot S0 → S1 completion and automatic proxy launch but did not provide the complete installation command/output transcript; the GitHub browser's actual page load and first-time new-key generation were not independently observed. First SSH transport slice is accepted via PR #5; complete S1 host provisioning and S1-D are not implemented/accepted by this evidence. Evidence derives from the owner's observations and logs, not remote execution by the assistant.

## Next work — S1-D Docker host candidate

- After accepted PR #5, the roadmap's **narrow functional S1 exit criterion**
  has owner-provided clean-VM setup, rerun, GitHub SSH and post-reboot evidence.
  Do not invent unspecified development tool requirements solely to keep S1
  open; milestone closure can be reviewed separately.
- [Draft PR #6](https://github.com/lehater/ai-lab/pull/6) proposes `bootstrap/docker/`: official Docker Engine /
  Compose installation with verified APT signing-key fingerprint, a
  dedicated systemd proxy drop-in, and `docker-test`, `docker-setup`,
  `docker-verify`, `docker-pull-test` Make targets.
- The owner fetched and checked out `feat/s1d-docker-host-proxy`
  on `lab-test` after accepted S0/S1; `make docker-test` reported:
  `PASS: Docker Shell syntax, stable APT repository template and daemon
  proxy template.` This validates **offline syntax/templates on the test VM**,
  not package installation, proxy/network reachability from Docker or daemon
  operation. Earlier local development-container test results remain separate.
- Owner then ran `make docker-setup` on `lab-test` and provided
  successful final output: `Docker Engine 29.9.2`,
  `Docker version 29.9.2, build a82e528`,
  `Docker Compose version v5.6.1`,
  `S1-D Docker host and daemon proxy: PASS (no image pull or container
  network checked)`, followed by `S1-D candidate: Docker Engine/Compose
  and daemon proxy configured; container networking/LAN security not yet
  verified`. This is **owner-provided installation and host/daemon-proxy
  success evidence**; complete APT installation logs were not provided.
- Owner then reran `make docker-setup` on `lab-test`, receiving
  `Docker Engine 29.9.2`, `Docker version 29.9.2, build a82e528`,
  `Docker Compose version v5.6.1`, and
  `S1-D Docker host and daemon proxy: PASS`. This supports **rerun
  compatibility** for the observed installed configuration; it is not
  a formal proof of full idempotency on every possible starting state.
- Owner immediately ran `make docker-pull-test`. The live daemon
  downloaded Docker Hub `library/hello-world:latest`, digest
  `sha256:11a3eb1597e864c51b3f56733cb2e8a90bf0c284bfc05f9444d81c558bc848aa`,
  and the container printed `Hello from Docker!`; the script reported
  `S1-D Docker registry pull and hello-world container: PASS.`
  This verifies authenticated or anonymous registry retrieval through
  the daemon's configured network path and container process execution,
  **not outbound HTTP(S) networking from a Docker bridge container**.
- After a reboot, owner provided `lab-test` console output for
  `make host-verify` (`S1 local config and proxied HTTPS: PASS`),
  `make docker-verify` (Docker Engine `29.9.2`, Docker Compose
  `v5.6.1`, daemon proxy PASS), and `make docker-pull-test`
  (same daemon PASS, proxy HTTPS PASS, Docker Hub `hello-world`
  already up to date, container prints `Hello from Docker!`,
  registry pull / container PASS). This verifies **post-reboot S0
  proxy connectivity, Docker daemon persistence, registry access and
  process startup** in the observed session. The latest log itself
  does not independently establish whether v2rayN was started
  automatically rather than manually; prior S0 autostart was separately
  confirmed in PR #5.
- Owner ran updated `make docker-test` on `lab-test`; it reported
  `PASS: Docker Shell syntax, stable APT repository template, daemon proxy
  template and bridge diagnostic contract.` Owner then ran
  `make docker-net-diagnose`. Observed:
  `xray` listens on **127.0.0.1:10808** (pid 3407);
  default Docker `bridge` gateway is **172.17.0.1**;
  `curlimages/curl:8.16.0` was pulled (digest
  `sha256:463eaf6072688fe96ac64fa623fe73e1dbe25d8ad6c34404a669ad3ce1f104b6`).
  Explicit proxy request from a bridge container via
  `host.docker.internal:10808` **failed** (`curl: (7)`, HTTP 000).
  A direct proxy-bypassing HTTPS request from the bridge container
  to `github.com` **succeeded (HTTP 200)**. The difference is
  consistent with the host listener bound to loopback only rather than
  to a bridge-reachable IP address, and confirms direct HTTPS
  bypass is possible on this Docker network. These are **observations
  on `lab-test`**, not evidence that Docker cannot use a future
  controlled proxy route or that LAN security has been proven.
- Network exploration on `lab-test` (experimental, **not required for
  baseline S1-D**): normal bridge container reached `github.com`
  directly (HTTP 200) and could not reach Xray via
  `host.docker.internal:10808` (HTTP 000; Xray bound to
  `127.0.0.1:10808`, bridge gateway `172.17.0.1`).
  `make docker-internal-probe` created a temporary
  `--internal` bridge (gateway `172.18.0.1`) and recorded direct
  HTTPS failure (HTTP 000) caused by a **DNS resolution timeout**;
  it confirmed temporary network cleanup. DNS failure alone does not
  prove all IP routes blocked. The unexecuted, bridge-only systemd
  `forwarder-probe` was only a candidate.
- **Scope decision D-011 (owner-approved):** defer a universal
  proxy-only/restricted-egress architecture and corresponding custom
  Docker networking tests until a real workload requires them.
  Remove experimental `docker-net-diagnose`,
  `docker-internal-probe`, `docker-forwarder-probe` scripts and
  Make targets from the proposed baseline PR; retain the above
  observations as engineering evidence.
- **Qualification at the earlier PR #6 checkpoint:** integrated
  clean-snapshot installation was not yet documented at that point;
  it was subsequently **owner-confirmed** and is recorded in the
  dedicated integrated replay evidence section below. External
  LAN-host exposure and enforced container proxy-only routing were
  not tested and are **not** part of the functional acceptance.
  The simplified `make docker-test` and the local port inspection
  had independently passed.

- After pruning the experimental network tools per D-011, owner ran
  `git pull` on `lab-test` (reported 10 changed files), then
  `make docker-test`: `PASS: Docker Shell syntax, stable APT repository
  template and daemon proxy template.` Also ran `make docker-verify`:
  Docker Engine `29.9.2`, Docker CLI build `a82e528`, Compose
  `v5.6.1` and `S1-D Docker host and daemon proxy: PASS`.
  This is live verification of the **reduced current candidate revision**,
  not a fresh clean-snapshot replay or a Compose service smoke test.
- Owner fetched the revised Compose-smoke candidate on `lab-test`
  (`git pull` reported six files changed) and ran `make docker-test`:
  `PASS: Docker Shell syntax, APT/daemon-proxy templates and Compose
  smoke contract.` Then ran `make docker-compose-test` with an ephemeral
  `hello-world` service. Compose created network
  `ailab-composesmoke-5014_default` and container
  `ailab-composesmoke-5014-smoke-1`, printed `Hello from Docker!`,
  reported container exit code `0`, checked
  `Docker Compose default network: bridge, internal=false; no published
  ports`, and `docker compose down` removed both service and network.
  Final output: `PASS: Docker Compose default bridge service and
  cleanup.` This confirms the default Compose service/network
  lifecycle on the current test machine. It does **not** confirm
  container-level proxy routing or independently inspect unrelated
  running containers and their published ports.
- The proposed S1-D **host/Compose functional slice is now owner-tested**
  on `lab-test`: initial/repeat setup, docker daemon proxy, image pull,
  Compose, and post-reboot daemon/registry checks. **Still pending:**
  external LAN access checks, which are not needed for the documented
  functional acceptance but remain necessary for LAN-safety claims. Restricted
  egress and custom forwarders remain deferred under D-011. First slice accepted in PR #6; integrated functional replay later owner-verified.

- Final local port inspection after Compose smoke on `lab-test`:
  `sudo docker ps` showed no running containers and therefore no
  published container ports. The host `ss -lntp` filter for
  2375, 2376 and 10808 showed only Xray listening at
  `127.0.0.1:10808`. No Docker API listener on 2375/2376 was
  observed. This **point-in-time local check is not an external
  LAN negative test** and says nothing about ports that later
  workloads might publish. First Docker/Compose bootstrap slice
  accepted through [PR #6](https://github.com/lehater/ai-lab/pull/6);
  this was the earlier checkpoint; a subsequent clean-snapshot
  full replay is owner-confirmed in the integrated evidence above.

## Integrated replay evidence — owner-confirmed clean snapshot

**Environment and provenance.** On 2026-10-22 the owner explicitly
confirmed restoring `lab-test` to `vmware-tools-ready` and then
running the **entire S0 → S1 → S1-D installation sequence using the
repository scripts**, followed by the final tests provided in the chat.
This is not simply a validation of a preconfigured machine.
The snapshot includes VMware Tools but originally had no installed
S0/S1/Docker AI Lab stack. Intermediate setup stdout and the exact
`git rev-parse HEAD` from that run were not pasted, so the full
sequence is **owner-attested**, while end-state tests are evidenced
by the supplied terminal output.

**Final terminal observations from that replay:**

- `make host-verify`: `S1 local config and proxied HTTPS: PASS`.
- `make github-verify`: GitHub authenticated the `lehater` user,
  followed by `S1 GitHub SSH authentication: PASS`.
- `make docker-verify`: Docker Engine `29.9.2`, CLI build `a82e528`,
  Compose `v5.6.1` and daemon proxy PASS.
- `make docker-pull-test`: Docker Hub `hello-world:latest` image
  successfully retrieved; the container printed `Hello from
  Docker!` and the registry/container test passed.
- `make docker-compose-test`: created `ailab-composesmoke-7366_default`
  network and `ailab-composesmoke-7366-smoke-1` container, exited
  successfully with code `0`, confirmed `bridge/internal=false` and
  no published ports, and removed both objects. Compose smoke PASS.
- Final `docker ps` showed no running containers; the filtered
  `ss -lntp` output showed Xray on `127.0.0.1:10808` only, with
  no Docker API listener on 2375/2376.

**Acceptance:** The functional, operator-assisted S0 → S1 → S1-D
installation is **reproducible on the declared Ubuntu 24.04 Desktop
/ VMware test baseline**, based on the owner's confirmed clean
snapshot restoration plus supplied final PASS evidence. S1-D's
functional milestone gate is satisfied on that platform. Earlier
owner reports independently documented setup reruns and post-reboot
checks; the most recent output contains end-state tests, not a
separate reboot transcript.

**Limitations:** not a fully unattended first launch (v2rayN GUI and
GitHub SSH enrollment are operator steps), not a bare-metal or other
hypervisor test, no externally verified LAN isolation, no mandatory
container proxy-only egress (D-011), no package pinning, and no
Enterprise-grade certification. The complete USB replay procedure
is retained in [bootstrap/README.md](../../bootstrap/README.md).

## Known environments

- **`lab`**: Ubuntu 24.04.5 Desktop / VMware, 8 vCPU, 16 GB RAM,
  150 GB ext4 disk. Manually configured v2rayN, GitHub SSH,
  Docker Engine/Compose, proxy networking and LAN isolation.
  See [observed environment](../current-environment.md).
- **`lab-test`**: separate Ubuntu 24.04.5 Desktop / VMware VM,
  100 GB virtual disk. Clean snapshot `vmware-tools-ready`
  (VMware Tools already installed) used for S0 recovery validation;
  baseline initially had neither Git nor v2rayN nor a running proxy.
- **Target later:** native Ubuntu (not yet validated by this bootstrap).
  Current S0 explicitly supports VMware only.

## Evidence and constraints

- S0 end-to-end checks on clean `lab-test`: v2rayN installed,
  Xray listened on `127.0.0.1:10808`,
  GitHub HTTP and SOCKS5 returned 200, APT installed packages,
  `git clone` of `lehater/ai-lab` succeeded, Stage 0 reported PASS.
- The initial Xray check failed once when Enter was pressed
  before manually opening v2rayN. This was an operator sequence issue:
  manual first GUI launch is documented and preserved by design.
- S0 success does **not** prove VMware Tools install from scratch,
  because the S0 test snapshot already contained VMware Tools.
- `docs/current-environment.md` reflects observed `lab` state
  and must not be read as clean-VM reproducibility evidence.
- No GitHub CI checks were configured for PR #1; machine tests were manual.

## Active work / handoff

1. S0, the first S1 GitHub SSH module, and Docker/Compose S1-D have
   owner-verified functional replay evidence from restored `lab-test`.
   Their specific accepted scopes and manual steps remain documented.
2. Full S1-D functional installation has been demonstrated; do not
   continue researching mandatory container proxy-only networking
   without a concrete workload (D-011).
3. Evaluate the next infrastructure increment S2 against an actual
   research requirement. Preserve repeatability and explicit
   qualification of all security and portability claims.
## Status vocabulary

- **NOT STARTED / NOT IMPLEMENTED**: no committed, verified implementation.
- **IN PROGRESS**: implementation underway, not accepted.
- **CONFIGURED, NOT VERIFIED**: code or settings exist, acceptance proof absent.
- **VERIFIED MVP**: the stated limited acceptance path was demonstrated.
- **DEFERRED / BLOCKED**: explicitly postponed / prevented by a dependency.

Only change a milestone to VERIFIED with an explicit test and evidence.

