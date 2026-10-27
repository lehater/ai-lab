# Local execution handoff — Multi-Agent E2E

**Purpose:** continue PR #24 on a local Ubuntu host, using only this repository,
this document, and the linked fixture runbook. **STOP after preparing results
for review; do not merge the PR or modify `main`.**

**Immutable prepared-code revision:** `534c92f187a86c3eff7c9070ed059721d3611fdd`
(contains the V2 config, failing fixture, test suite and static verifier).
**Branch to execute:** `proposal/multi-agent-e2e-first-slice`.
The handoff itself and later documentation are subsequent commits; always
fetch this branch and record the **exact resulting HEAD** in evidence.
Require `534c92f...` to be an ancestor; stop on unexpected history.
Base `main` at planning time was `8584437c23dbb6fbdd8311c8080f6e7cc4f1ee43`.
PR: https://github.com/lehater/ai-lab/pull/24

## Ready-to-use prompt for the Ubuntu agent

> You are the local execution agent for the Multi-Agent E2E pilot of AI Lab.
> Your authority is limited to this experimental branch and disposable test
> workspaces. Treat merged `main` as accepted project authority; this branch
> describes an unaccepted research experiment.
>
> **1. Recover state, record revisions, do not disturb existing work.**
> Read `AGENTS.md`, `docs/project/{strategy,state,roadmap,decisions}.md`,
> `docs/proposals/2026-10-27-multi-agent-e2e.md`, this handoff, and
> `experiments/multi-agent-e2e/README.md`. Inspect `git status --short`
> before any checkout. If the existing clone has uncommitted changes, **STOP
> and ask**; use a new separate clone only after operator approval.
> In a clean local checkout:
>
> ```bash
> git fetch origin proposal/multi-agent-e2e-first-slice main
> git switch proposal/multi-agent-e2e-first-slice
> git pull --ff-only origin proposal/multi-agent-e2e-first-slice
> test "$(git branch --show-current)" = proposal/multi-agent-e2e-first-slice
> git merge-base --is-ancestor 534c92f187a86c3eff7c9070ed059721d3611fdd HEAD
> git status --short
> git rev-parse HEAD
> ```
>
> Save the full observed HEAD SHA. Do not rewrite branch history, create a
> new branch, edit `main`, or merge PR #24. Compare accepted decisions and
> this branch; if they conflict, stop and request direction.
>
> **2. Gate 0 (environment and consent).** Select ONE execution host: prefer
> the WSL2 Ubuntu installation with GPU-backed Ollama *only if available and
> approved*; otherwise record the selected VMware Ubuntu target and its
> limitations. Follow Gate 0 commands in the README to capture: Ubuntu /
> kernel / VM or WSL, CPU/RAM, NVIDIA driver/GPU/VRAM and memory use,
> disk free, Python, Ollama/OpenCode exact versions, OpenCode V2 command
> compatibility, installed local models and their digests/context/tool use,
> OpenCode model inventory, loopback API reachability and observed errors.
> Use `ollama list`, `ollama show <actual-model>`,
> `curl -fsS http://127.0.0.1:11434/api/tags`, `opencode models`.
> No Ollama port publication, proxy change, OS update, `sudo`, package
> installation, model pull, firewall edit, credential discovery or
> registration, network reconfiguration or VM snapshot/rollback without
> **explicit owner authorization**. Check official docs and `--help` for
> this actual version. OpenCode **V1 configs are incompatible with V2**;
> stop if V2 is unavailable and obtain approval before installing/replacing.
>
> Resolve `ollama/qwen3-coder:30b` (candidate in fixture config), or
> choose an actually installed tool-capable Ollama model. If changed,
> modify **only the disposable fixture config** initially; include the
> exact resolved config and rationale in evidence and propose a follow-up
> repo change for review. OpenCode/Ollama docs suggest a long 64k+ context,
> but confirm memory use and realistic execution on this GPU. Verify
> external model/provider/account support using official OpenCode docs.
> ChatGPT account auth might be available in V2, but neither an active
> subscription nor an API key guarantees universal compatibility.
> **Stop for explicit owner approval of provider, model, possible cost and
> quota before making ANY billable or external-model request.**
> Do not reveal secrets or credential contents in evidence.
> If prerequisites/approval fail, set `BLOCKED` and do not fake a run.
>
> **3. Static preflight.** From the repo root execute:
>
> ```bash
> python3 experiments/multi-agent-e2e/verify_static.py
> ```
>
> Expected message: `STATIC PASS: JSON contract; fixture RED
> (1 expected failure); reference GREEN (6 tests)`. It is a
> code/fixture contract check, not proof of OpenCode E2E.
>
> **4. Create three independent disposable clones.** Follow the
> README's `Disposable workspace setup` *verbatim after inspecting each
> command*. The seed must have ONE captured `FIXTURE_BASE_SHA`; each
> cloud/local/dual clone must report that same initial SHA. Run
> `python3 -m unittest discover -s tests -v` at baseline; exactly ONE
> failure (touching half-open boundary) is expected. Never reset or clean
> the AI Lab repository itself. Keep raw files outside the Git tree in
> `$RUN_ROOT/evidence/raw`.
>
> **5. Gate 1: two isolated single-agent baselines.** Obtain approved
> `PILOT_EXTERNAL_MODEL` and verified `PILOT_LOCAL_MODEL`. Run the
> README's `Gate 1` OpenCode V2 commands from separate clones and
> `--agent pilot-solo` (subagents explicitly denied). Do not use
> `--auto`; if CLI approval prompts block a headless run, use
> interactive mode with the same permissions, recording exact usage.
> Preserve tool exit codes, actual session IDs and model information
> from output. After each attempt run the Python tests **independently**,
> `git diff --check`, `git diff -- scheduler.py`, `git status --short`.
> Only `scheduler.py` may change. Do not silently switch models or
> rerun with new prompts while presenting outcomes as comparable.
> Score cloud/local independently as PASS, FAIL, BLOCKED or NOT TESTED.
>
> **6. Gate 2: cloud primary → local read-only subagent → primary.**
> Start only on a NEW third clone from unchanged baseline, after Gate 1
> assessment and cost approval. Use `pilot-primary` with the external
> model, require an explicit `root-cause-reviewer` call before editing.
> The reviewer uses `ollama/<verified-local-model>` and has no shell/edit
> rights. After completion, run independent tests and inspect diff.
> Correlate actual OpenCode events and sanitized session exports to
> demonstrate provider/model of both invocations, parent→child call,
> child→parent result, primary change, independent green tests.
> Agent narrative alone is insufficient. A hidden substitution of external
> model for local reviewer is FAIL. If event format cannot prove the path,
> record `BLOCKED` for trace verification and preserve the blocker.
>
> **7. Record evidence using built-in OpenCode.** `opencode run --format json`
> emits structured events; `opencode session list --format json` identifies
> sessions, and `opencode session export <real-ID> --sanitize` creates a
> scrubbed export (check CLI help first). Save **raw** outputs in the private
> disposable directory, never in Git. Preserve for each attempt: exact
> AI Lab HEAD and fixture baseline SHA, timestamp, environment and resources,
> binary versions, installed model IDs/digests/context, provider and auth
> mechanism (type only), approvals/cost expectations, complete commands,
> tool exit status, elapsed duration, independent test result, changed
> filenames/diff, delegation evidence identifiers, exceptions and
> limitations. Review sanitized excerpts by eye for credentials, user
> directories, local proxy addresses/subscriptions and private data BEFORE
> inclusion in Git. The official `--sanitize` flag is useful but not
> a proof that everything confidential was removed.
>
> **8. Failure handling.** A failed command is not permission to perform
> increasingly invasive recovery. For V2 mismatch, missing model, auth
> failure, failed tool calling, overloaded GPU, port/connectivity failure,
> approval prompt problems or absent child metadata: stop the affected
> gate, retain minimal error message, exact triggering command and
> resources observed; assign `FAIL` if an executed correctness/safety
> check fails, `BLOCKED` if a prerequisite prevents the check, and
> `NOT TESTED` if it was never attempted. Do not declare a model run
> PASS from a conversational assertion. Ask before repeated billable
> calls, large downloads or modifications outside disposable workspace.
>
> **9. Prepare PR review, then STOP.** Copy
> `experiments/multi-agent-e2e/evidence/RESULTS.template.md` to
> `experiments/multi-agent-e2e/evidence/RESULTS.md`, fill in factual
> statuses and include safe, small reviewed artifacts only. If runtime
> config needed changes, propose/update the versioned fixture config in
> the working branch *only after* static verification. Commit in small
> logical units, update proposal status and PR #24 description, push
> ONLY `proposal/multi-agent-e2e-first-slice` after owner authorization
> for network writes. Record final SHA and note pending approvals.
> **Do not merge or relabel the PR as runtime-verified without evidence.**
> Return a brief status summary with PR link; leave detailed logs and
> the next-step plan in Git. **Stop at this handoff boundary.**
>
> **Success conditions:** Gate 0 confirms real versions, available
> permitted models and feasible resources; Gate 1 has an independent
> outcome for EACH baseline; Gate 2 shows actual two-backend, explicit
> read-only delegation, returned child result, bounded single-file code
> change and 6/6 independent tests; PR contains versioned configs,
> minimal trace evidence and reproducible commands. If any are missing,
> report accurately and STOP; do not install an alternative orchestrator
> or broaden the infrastructure scope without an explicit decision.

## Current handoff status

Prepared Git files have an independent **STATIC PASS** from
[GitHub Actions run #40506219906](https://github.com/lehater/ai-lab/actions/runs/40506219906):
configuration assertions and fixture RED→GREEN using hosted Ubuntu/Python.
**Gate 0, Gate 1, Gate 2: NOT TESTED on the target Ubuntu/OpenCode/Ollama.**
No credentials or hardware status have been inferred from prior chats.
The code revision above anchors the implementation, not the observed
branch head that the local agent must record at the start.

## References

- [Fixture/runbook](../../experiments/multi-agent-e2e/README.md)
- [Evidence template](../../experiments/multi-agent-e2e/evidence/RESULTS.template.md)
- [OpenCode V2 agents](https://opencode.ai/v2/docs/agents)
- [OpenCode V2 permissions](https://opencode.ai/v2/docs/permissions)
- [OpenCode V2 providers](https://opencode.ai/v2/docs/providers)
- [OpenCode V2 CLI](https://dev.opencode.ai/v2/docs/cli/commands)
- [Ollama/OpenCode](https://docs.ollama.com/integrations/opencode)
