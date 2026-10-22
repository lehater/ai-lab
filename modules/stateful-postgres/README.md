# S2 candidate: stateful Compose / backup and isolated restoration

**Status: DRAFT / NOT RUN on lab-test.** This is a **disposable functional
test fixture**, not an AI app or permanent PostgreSQL requirement. Do not
assume S2 is complete because this Compose project can run.

## Contract

- Standard S1-D `sudo docker compose`, no Ansible: Compose owns containers.
- Two Postgres **17** services, `db` (active) and `restore-db` (profiled).
  They use **different named volumes** mounted at
  `/var/lib/postgresql/data` (required for Postgres <=17).
- Secret password is generated locally by the operator into
  `private/db_password.txt` (0600, gitignored); Docker Compose mounts a
  file-backed secret at `/run/secrets/db_password`. No password content in
  Docker environment variables or Git.
- No published ports; normal Compose bridge networking follows D-011.
- Health/readiness via `pg_isready`, plus SQL verification independent of
  the Docker "healthy" flag.
- Seed row survives a **container force-recreate** using the primary volume.
- Take a binary `pg_dump -Fc` into a private host-side backup (0600).
- Restore using `pg_restore` to **a separate fresh Compose project with a
  distinct named volume**, then compare the seeded row. Restore fixture is
  removed using only its own `down --volumes`; the original stays intact.
- `cleanup` requires an explicit environment approval and removes only this
  named Compose project's volumes; it retains local private backups/secrets
  for operator review. **Never run Docker prune globally.**

## Operator runbook (independent disposable lab-test VM)

Prerequisite: owner-confirmed S0/S1/S1-D baseline, a working S0 proxy for
Docker registry pulls, and a saved VMware snapshot. Docker Engine's proxy
permits registry downloads; it does **not** apply to outgoing connections
inside containers.

```bash
cd ~/projects/ai-lab
git fetch origin
git switch feat/s2-compose-stateful-recovery-fixture
git pull --ff-only origin feat/s2-compose-stateful-recovery-fixture
git rev-parse HEAD
cd modules/stateful-postgres

bash -n pilot.sh
bash pilot.sh init
# Review private .env before using it. In this first proposal:
# POSTGRES_IMAGE=postgres:17 is a moving MAJOR tag (NOT digest-pinned).
grep '^POSTGRES_IMAGE=' .env
bash pilot.sh config
bash pilot.sh test

# Review private backup list/digests without sharing backup bytes:
ls -lh private/backups/
sha256sum private/backups/*.dump

# After saving the evidence and approving destruction ONLY of this fixture:
AI_LAB_ALLOW_PILOT_TEARDOWN=YES bash pilot.sh cleanup

cd ~/projects/ai-lab
make host-verify
make github-verify
make docker-verify
make docker-compose-test
```

**Do not run `cleanup` on any unrelated Docker project** or skip reviewing
volumes. The script uses project `ai-lab-s2-pg-pilot` for the primary,
and a new `ai-lab-s2-pg-pilot-restore-...` project for the restore. The
project's local `private/` and `.env` remain after cleanup. No root
Docker group membership is introduced: commands use `sudo docker compose`.

## Image pinning and license

This implementation deliberately starts from the upstream **Docker Official
Image** [Postgres](https://hub.docker.com/_/postgres) as a *candidate*.
`postgres:17` is a moving major tag, **not a reproducible exact image**.
Before calling the pilot portable or reproducible, resolve and record the
image manifest digest and platform for this VM, then set
`POSTGRES_IMAGE=postgres@sha256:<digest>` in the untracked local
`.env` and rerun on a clean independent clone. Do not claim digest pinning
or stable image supply until this is tested. PostgreSQL core uses the
[PostgreSQL License](https://www.postgresql.org/about/licence/), a
permissive Open Source license; the complete container image also contains
other OS/library packages with their own licenses.

## What success does NOT prove

- A named volume surviving container recreation is **not** a backup.
- A saved dump is not a recovery proof until a restore into a **fresh
  different** volume succeeds and data are independently queried.
- `pg_isready` is a coarse readiness signal, **not** an application smoke.
- A Compose file without `ports:` does not prove LAN isolation, and the
  script checks Docker port bindings on the primary container at runtime.
- The demonstration secret is temporary; it is **not a Vault/KMS**, secret
  rotation implementation or an encryption-at-rest guarantee.
- A one-row recovery test is **not** a durable retention or disaster recovery
  plan, storage migration policy, encrypted off-VM backup or point-in-time
  recovery implementation.
- It does not demonstrate failure recovery after storage corruption, policy
  controls, or HA. These remain explicit future needs.

## Evidence before any merge

Record: source Git SHA, VM/snapshot, exact image reference and actual
container digest (and architecture), Compose version, whether registry pull
succeeded, config/lifecycle/SQL PASS or FAIL, selected backup checksum
(**not the secret or dump itself**), docker-published-port inspection,
separate restore project/volume names, scoped teardown outputs, reboot
behavior if tested, and regressions of accepted baseline commands.

A failing or interrupted run may leave data volumes and/or a separately
named restore project for inspection; record and explicitly clean only
that project after diagnosis. **No lab-test commands have been executed by
the assistant**, and this PR cannot claim PASS without operator logs.

References:
- https://docs.docker.com/compose/gettingstarted/
- https://docs.docker.com/reference/compose-file/secrets/
- https://docs.docker.com/reference/compose-file/volumes/
- https://docs.docker.com/compose/how-tos/startup-order/
- https://hub.docker.com/_/postgres
