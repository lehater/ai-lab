# AI Lab

**Оператору:** [полная инструкция установки с USB, S0 → S1](bootstrap/README.md)
(локально на флешке: `USB/bootstrap/README.md`). Запускать можно без
доступа к чату; порядок и проверки приведены в одном месте.

**AI Lab** — a modular, reproducible infrastructure laboratory for deploying and studying different AI technologies and systems. **Enterprise-grade engineering is the long-term aspiration, not the current verified status.** Development follows Infrastructure as Code, command-driven provisioning, automated checks and evidence-based adoption of mature tools.

The deliverables are reusable infrastructure modules, versioned configurations and tested research-environment templates. AI scenarios (including Agentic SDLC) are independent consumers of this infrastructure, not the repository mission or a mandatory technology stack.

## Project knowledge

- [AGENTS.md](AGENTS.md) — entry point for agents and new work.
- [Strategy](docs/project/strategy.md) — mission, long-term target and engineering principles.
- [Roadmap](docs/project/roadmap.md) — incremental infrastructure milestones and acceptance gates.
- [State](docs/project/state.md) — facts, verified baseline and implementation limits.
- [Decisions](docs/project/decisions.md) — accepted engineering choices and boundaries.
- [Research guide and index](docs/research/README.md) — rules for research documents, evidence standards and index.
- [Research: platform landscape](docs/research/2026-10-22-platform-landscape.md) — exploratory comparison of AI research environments, self-hosted deployment tools and templates (not an accepted decision).
- [Observed environment](docs/current-environment.md) — manually configured reference VM, not clean-VM IaC proof.
- [USB quick start](bootstrap/README.md) — ordered S0 → S1 operator runbook, carried on USB with `bootstrap/`.
- [Stage 0 bootstrap](bootstrap/stage0/README.md) — limited, independently tested offline VMware bootstrap.

## Operational commands (first S1 slice)

After the independent S0 bootstrap and repository checkout, S1 provides
`make help`, `make host-setup`, `make github-setup`, `make github-verify`,
`make host-verify` and `make host-test`. If `make` is missing, use
`bash bootstrap/host/bootstrap.sh` once to install it through S0's APT
proxy. The [host instructions](bootstrap/host/README.md) cover
operator-owned SSH key enrollment, browser proxy limitations and acceptance.
The guided setup and checks were owner-tested after a clean-snapshot replay
and accepted in [PR #5](https://github.com/lehater/ai-lab/pull/5).
**Full S1 host provisioning remains incomplete.**

## Docker Engine/Compose bootstrap — integrated functional replay verified

[Merged PR #6](https://github.com/lehater/ai-lab/pull/6) provides
`make docker-setup`, `make docker-verify`, `make docker-pull-test`,
`make docker-compose-test` and `make docker-test`.
Owner-verified on `lab-test`: Docker Engine 29.9.2, Compose v5.6.1,
daemon proxy, initial/repeat setup, image pull, post-reboot operation,
and default Compose bridge service/cleanup.
Normal Compose networking remains the default (D-011);
app-level forced proxy egress is deferred.
Final local inspection found no running containers or Docker API
TCP listeners. Owner explicitly confirmed restoring `lab-test` to the original
`vmware-tools-ready` snapshot, reinstalling the full S0 → S1 → S1-D
stack through scripts and receiving the final functional PASS outputs.
**S1-D's functional milestone is verified on the supported VMware
baseline**, with manual first-run steps. No externally validated LAN
isolation, automatic first GUI launch, pinning or portability to other
platforms is claimed.

Only merged `main` is authoritative. The verified Stage 0 MVP is a first step toward the target, not evidence of full unattended deployment or Enterprise-grade compliance. See [roadmap](docs/project/roadmap.md) for the next testable increment.
