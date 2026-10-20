# AI Lab

Reproducible Enterprise AI Engineering laboratory.

## Project knowledge (source of truth)

- [AGENTS.md](AGENTS.md) — entry point for new chats, agents and contributors.
- [Current project state](docs/project/state.md) — verified baseline, gaps and handoff.
- [Execution roadmap](docs/project/roadmap.md) — next tasks and acceptance gates.
- [Engineering decisions](docs/project/decisions.md) — accepted bootstrap choices.
- [Observed development environment](docs/current-environment.md) — manually configured `lab` VM.
- [Stage 0 offline USB bootstrap](bootstrap/stage0/README.md) — validated VMware recovery.

The merged `main` branch is authoritative for accepted implementation.
A separate [AI Lab strategy PR #2](https://github.com/lehater/ai-lab/pull/2)
is **PROPOSED** and is not treated as adopted here.

## Environments

- VMware Ubuntu 24.04 LTS — development and validation
- Native Ubuntu 24.04 LTS — target deployment

## Components

1. Host Bootstrap — Ubuntu, proxy, Docker, networking
2. AI Platform — infrastructure and model services
3. AI Application — RAG, agents, integrations

## Principles

- Infrastructure as Code
- Reproducible deployment
- Secrets outside Git
- Incremental implementation
