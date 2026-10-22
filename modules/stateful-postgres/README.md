# S2: minimal backup/restore integration candidate

**Draft / NOT RUN on `lab-test`.** Disposable PostgreSQL **17** fixture
only. PostgreSQL is not a mandatory AI Lab service.

## Why this exists

Docker Compose named-volume persistence, file-backed secrets, `pg_dump` and
`pg_restore` are established, documented upstream features. We do **not**
need a new test suite to prove them. This pilot checks just the risky
**integration we wrote**: whether a dump made by our script can be restored
into a **different fresh Docker volume** and queried successfully.

## Scope

- `compose.yaml`: PostgreSQL `db` and opt-in `restore-db` service with
  **independent named volumes**, a file-backed password under
  `private/db_password.txt`, basic readiness and **no published ports**.
- `pilot.sh init`: create local gitignored password and `.env` using
  restrictive permissions. Review `.env` if using a custom image.
- `pilot.sh test`: `docker compose config -q`, start the primary service,
  write a known row, `pg_dump -Fc` into a private backup, create a unique
  **separate recovery project/volume**, `pg_restore`, query that row and
  compare the actual value. On success remove **only recovery** containers
  and their volume; keep the primary project and backup.
- `pilot.sh cleanup`: explicit
  `AI_LAB_ALLOW_PILOT_TEARDOWN=YES` required to delete **only the primary
  pilot project volumes**. Never use `docker prune`, never remove another
  project or the locally retained backup/password.

The service's `pg_isready` healthcheck is a standard readiness setting,
**not** a research subject. Named-volume survival across forced recreation,
Docker registry pulls, host SSH, GUI reboot, LAN firewall behavior and
PostgreSQL backup algorithms are **not** separate acceptance exercises
for this small change.

## Minimal operator verification

Only on the disposable `lab-test` Ubuntu VM with working Docker/Compose.
Do not run on the reference `lab` or a machine containing a project with
the same name `ai-lab-s2-pg-pilot`.

```bash
cd ~/projects/ai-lab
git fetch origin
git switch feat/s2-compose-stateful-recovery-fixture
git pull --ff-only origin feat/s2-compose-stateful-recovery-fixture
git rev-parse HEAD

cd modules/stateful-postgres
bash -n pilot.sh
bash pilot.sh init
grep '^POSTGRES_IMAGE=' .env  # public image ref, not the private password
bash pilot.sh test             # one decisive integration test
```

**Acceptance:** `PASS: backup restored and independently read in separate
fresh volume.` Confirm `failed`/nonzero exit is absent; the same script
uses `set -Eeuo pipefail`. Record Git SHA, image reference and the command
outcome in `docs/project/state.md`. Do **not** require a second clean-snapshot
bootstrap or repeat full S0/S1/S1-D regression unless this PR changes those
dependencies. Do not run `cleanup` to demonstrate Docker deletion semantics.

After you have reviewed the fixture, optional scoped cleanup:

```bash
AI_LAB_ALLOW_PILOT_TEARDOWN=YES bash pilot.sh cleanup
```

Cleanup does not remove `.env`, `private/db_password.txt`, or backup
dumps. Treat dumps as potentially containing data and do not commit them.

## Boundaries

- This is a *test fixture for an integration*, not a general backup system,
  reusable database module or a completed S2 milestone.
- The example `postgres:17` tag is **moving**, not digest-pinned.
  Record an immutable digest if comparing exact replay results across
  machines; it is not required to discover whether **this script's** restore
  path works once on a disposable local fixture.
- Passwords and dumps remain untracked. This does not prove production
  secret rotation, encrypted remote backups or disaster recovery.
- Unexpected failure may leave an isolated recovery project for diagnosis.
  Do not globally prune Docker; inspect the project name reported in
  command output and clean only that named project.
- A successful restore proves only the fixture's known row was recovered,
  not production completeness or consistency guarantees.

References:
- https://docs.docker.com/reference/compose-file/secrets/
- https://docs.docker.com/reference/compose-file/volumes/
- https://www.postgresql.org/docs/17/backup-dump.html
- https://hub.docker.com/_/postgres
