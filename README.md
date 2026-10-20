# AI Lab

Reproducible engineering lab researching and validating **controlled Agentic SDLC**: preserving requirements, architecture and independent verification across successive AI-assisted software changes. First experimental product: AI Lab itself.

## Project knowledge

- [AGENTS.md](AGENTS.md) — entry point for agents and new work.
- [Strategy](docs/project/strategy.md) — accepted mission, boundaries and principles.
- [Roadmap](docs/project/roadmap.md) — stages and acceptance gates.
- [State](docs/project/state.md) — verified implementation and next task.
- [Decisions](docs/project/decisions.md) — accepted engineering choices.
- [Observed environment](docs/current-environment.md) — manually configured reference VM.
- [Stage 0 bootstrap](bootstrap/stage0/README.md) — tested offline VMware bootstrap.

Only merged `main` is authoritative. The [strategy accepted in PR #2](https://github.com/lehater/ai-lab/pull/2) guides decisions, but does not imply that planned milestones or capabilities are implemented.

Infrastructure progresses in small independently testable stages (S0, S1, S1-D, S2); the first bounded Agentic SDLC experiment can reuse S1 development **without waiting for a full AI runtime**. See [roadmap](docs/project/roadmap.md) for scope and acceptance gates.
