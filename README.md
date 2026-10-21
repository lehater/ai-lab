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

## Next candidate: S1-D Docker Bootstrap

[Docker first slice](bootstrap/docker/README.md) provides proposed
`make docker-setup`, `make docker-verify`, `make docker-pull-test`,
`make docker-test`. These commands configure Engine/Compose and the
**daemon** proxy only. This work is in a separate draft PR; it is **not yet
verified on `lab-test` or merged into `main`**. Bridge-container proxy
routing and LAN isolation remain separate acceptance conditions.

Only merged `main` is authoritative. The verified Stage 0 MVP is a first step toward the target, not evidence of full unattended deployment or Enterprise-grade compliance. See [roadmap](docs/project/roadmap.md) for the next testable increment.
