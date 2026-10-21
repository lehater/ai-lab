# AI Lab — instructions for agents and new chats

This is the entry point for all work on `lehater/ai-lab`.
**The merged `main` branch is the source of truth for accepted project state.**
An open PR is a proposal; a chat transcript, recollection, and uncommitted
machine changes are not accepted repository state.

## Read first (in this order)

1. [Strategy](docs/project/strategy.md) — accepted purpose, boundaries and engineering principles.
2. [Current project state](docs/project/state.md) — implemented, verified, unverified, blocked, next handoff.
3. [Roadmap](docs/project/roadmap.md) — ordered work and acceptance gates, not a claim of completion.
4. [Decisions](docs/project/decisions.md) — accepted choices and deferrals.
5. [Observed development environment](docs/current-environment.md) — manually configured `lab`, **not** proof of Infrastructure as Code.
6. [USB operator runbook](bootstrap/README.md) — complete S0 → S1 bootstrap sequence on the USB media.
7. [Stage 0 instructions](bootstrap/stage0/README.md) — offline VMware USB details, if relevant.
8. [README](README.md) — repository overview.

## Before starting work

- Check actual `main`, open PRs and working branch. Do not assume what a prior chat completed.
- Identify the target milestone and current acceptance status in
  `docs/project/state.md`; use `docs/project/roadmap.md` for the next task.
- Inspect existing source files before editing. Keep scope small and
  reproducible; prefer a feature branch and PR for review.
- Treat Enterprise-grade as an **aspirational target**, never as current verification status. Prefer Infrastructure as Code, reusable templates, documented operator steps, and clean-environment checks; do not embed a specific research scenario into the core by default.
- Use the tested `lab-test` VMware snapshot for validation of bootstrap
  changes. Do not mistake results from manually configured `lab` for
  clean-machine reproduction.
- Never commit private proxy archives, subscription URLs, SSH private keys,
  tokens, local credentials, or actual machine secrets.

## How to record progress

- **Code and evidence in the same PR:** update `docs/project/state.md` when
  implementation or validation status changes. Record what command/test ran,
  on which environment, its outcome, and limitations.
- Update `docs/project/roadmap.md` when priorities, next task or acceptance
  gates change.
- If bootstrap scripts, Make targets or operator steps change, update
  `bootstrap/README.md` in the same PR. The USB is a separately copied
  artifact: document the required re-copy; never delete its private payload.
- Add an entry to `docs/project/decisions.md` only when a decision is
  explicitly accepted. Keep proposals in their PRs, not as accepted decisions.
- Do not mark anything VERIFIED/PASS if it was only written, reviewed,
  installed manually, or tested on a different environment. Do not describe a partially interactive install as fully unattended.
- If a test fails, preserve the failure and a reproducible next step instead
  of overwriting it with an optimistic status.
- After merge, `main` takes precedence over stale PR descriptions and
  chat summaries. Update links when files move; remove obsolete references.

## Handoff between chats / agents

Read the files above, then report: current verified baseline, open work,
next smallest testable task, and its acceptance condition. At the end of a
work session, leave a brief factual update in the repository through a PR
or explicitly state that progress has not yet been committed. Do not create
duplicate planning systems or assume an unmerged PR is accepted.
