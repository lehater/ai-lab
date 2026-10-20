# AI Lab

Reproducible AI engineering lab. First use case: develop and improve AI Lab itself through independently verified human/agent workflows.

## Project knowledge

- [AGENTS.md](AGENTS.md) — entry point for agents and new work.
- [Strategy](docs/project/strategy.md) — accepted mission, boundaries and principles.
- [Roadmap](docs/project/roadmap.md) — stages and acceptance gates.
- [State](docs/project/state.md) — verified implementation and next task.
- [Decisions](docs/project/decisions.md) — accepted engineering choices.
- [Observed environment](docs/current-environment.md) — manually configured reference VM.
- [Stage 0 bootstrap](bootstrap/stage0/README.md) — tested offline VMware bootstrap.

Only merged `main` is authoritative. The [strategy accepted in PR #2](https://github.com/lehater/ai-lab/pull/2) guides decisions, but does not imply that planned milestones or capabilities are implemented.

Infrastructure is built in small, independently testable stages (S0, S1, S1-D, S2), followed by model integration and real engineering workflows. See [roadmap](docs/project/roadmap.md) for current boundaries.
