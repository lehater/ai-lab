# S2.1 — disposable stateful Compose acceptance pilot

**Status: CANDIDATE, NOT VERIFIED on `lab-test`.** This is an acceptance
fixture for the Infrastructure Core lifecycle contract, **not** a PostgreSQL
module, installed lab service, required AI platform, or general backup system.

## Purpose and boundaries

Prove that the existing S1-D Docker/Compose baseline can operate **one**
stateful service using only standard Docker tools: versioned Compose config,
a private host secret delivered via Compose, healthcheck, named-volume
persistence across container recreation, logical backup, restoration into a
second clean volume, diagnostics, and clean removal.

The experiment runs two short-lived PostgreSQL 17 Alpine instances,
without published ports, in uniquely named Compose projects. The private
password and SQL dump live in a mode-0700 temporary directory outside Git
and are deleted after the test. Both project-scoped volumes are removed
after the test, including on failure if Docker remains available.

## Run on lab-test (Ubuntu 24.04 / VMware, after S0 → S1 → S1-D)

From a feature-branch checkout:

```bash
git rev-parse HEAD
make docker-verify
make s2-config-test   # shell syntax and docker compose config
make s2-smoke         # real container lifecycle; requests sudo
sudo docker ps --format 'table {{.Names}}\t{{.Ports}}'
```

Expected: `PASS: S2.1 shell syntax and Compose configuration.` and
`PASS: S2.1 secret, health, no published ports, persistence, logical
backup/restore and cleanup.` Preserve checkout SHA, image ID, the PASS
lines, and failure evidence (without secrets). For a clean-environment
claim, run after the accepted S0 → S1 → S1-D baseline has been reproduced
on `lab-test`; the pilot by itself does not reinstall Docker.

The script uses `sudo docker` (never changes Docker group membership).
No custom ingress or proxy-only egress is introduced (D-011). The
Docker daemon uses the S1-D proxy to pull the image. The containers'
outbound routing is not restricted or tested. An existing network exposure
policy is **not** established by a negative port-binding check.

## Failure and removal

On failure the script prints the primary service's `ps` and last 50 log
lines and attempts to delete **only its own two random Compose projects,
networks and named volumes**. A cleanup failure prints the project name
for manual investigation; do not run broad `docker volume prune` or
`docker system prune` as a workaround. Nothing is installed permanently.

The current image reference `postgres:17-alpine` is a floating minor tag,
not a digest pin; the test prints the local image ID for traceability.
The logical `pg_dump` / `psql` restore is PostgreSQL-specific. It proves
this fixture's restore path only, not a generic volume backup policy,
scheduled backup retention, encryption at rest, or failure recovery after
a VM loss. File-backed Compose secrets are bind mounts, **not encrypted
vault storage**. For real services, secrets need a separately evaluated
storage and rotation mechanism.

## Acceptance and next decision

Only mark S2.1 verified after the commands have actually passed on
`lab-test` with the result recorded in `docs/project/state.md`.
Then select a **real consumer** before generalizing conventions or adding
a catalog, service manager, persistent database, Terraform or Ansible.
