# Multi-Agent E2E pilot — OpenCode V2 (experimental)

**Status: PREPARED / RUNTIME NOT TESTED.** This is an isolated *research
consumer* of AI Lab, not an infrastructure module or an adopted runtime.
See [proposal](../../docs/proposals/2026-10-27-multi-agent-e2e.md) and
[local handoff](../../docs/proposals/multi-agent-e2e-local-handoff.md).

## Contract and layout

- `fixture/TASK.md`: same coding task for all three runs.
- `fixture/scheduler.py`: intentionally buggy half-open interval predicate.
- `fixture/tests/test_scheduler.py`: 6 stdlib unittest cases, 1 expected FAIL.
- `fixture/opencode.json`: **OpenCode V2** providers + permissions + 3 agents.
- `verify_static.py`: schema/permissions assertions and independent RED/GREEN
  fixture check, no model calls or third-party Python packages.
- `evidence/RESULTS.template.md`: fill in factual outcomes after local work.
- `evidence/raw/`, `_runs/`, and `private/`: **ignored**, never push raw traces.

The only allowed agent mutation is `scheduler.py` in a disposable **clone**.
Primary models are selected explicitly via CLI. The local subagent example
uses `ollama/qwen3-coder:30b` **as a candidate, not an observed installation**;
verify the model ID before running. V2 discovers the local Ollama server at
`127.0.0.1:11434` (config uses `http://127.0.0.1:11434/v1`).
The baseline agent is `pilot-solo`, and the dual agent is `pilot-primary`.
Only the latter may invoke `root-cause-reviewer` (local read-only subagent).

**Why V2?** V1 uses `agent/permission/bash/task`, while V2 uses
`agents/permissions/shell/subagent`; their configuration formats are not
interchangeable. Do not silently run V1 against this fixture. Run
`opencode --version` and `opencode run --help` before attempting a trial.
The installed exact OpenCode/Ollama/model versions must be recorded at Gate 0.

## Static verification (no OpenCode required)

From the AI Lab repository root:

```bash
python3 experiments/multi-agent-e2e/verify_static.py
```

Expected: `STATIC PASS: JSON contract; fixture RED (1 expected failure);
reference GREEN (6 tests)`. The checker copies the fixture into a temporary
directory and leaves the committed faulty source unchanged. This verifies a
**test fixture**, not OpenCode configuration compatibility with an installed
binary or any multi-agent execution.

## Gate 0 — prerequisites and approvals

Run the commands below **on the selected Ubuntu host**, preferably WSL2 with
the locally reachable Ollama; VMware and WSL2 are distinct test environments.

```bash
uname -a
python3 --version
free -h
df -h .
command -v nvidia-smi && nvidia-smi
command -v ollama && ollama --version && ollama list
curl -fsS http://127.0.0.1:11434/api/tags
command -v opencode && opencode --version
opencode run --help
opencode session export --help
opencode models
```

Check locally whether Ollama advertises the chosen model, and whether
the OpenCode build **actually identifies as V2** and loads `opencode.json`.
A version string alone may not distinguish every incompatible fork: inspect
CLI/config capability as well. If V2 is absent, **stop for operator approval
before installing or replacing an existing OpenCode**. Official installation:
`https://opencode.ai/download` (`@opencode/cli` for V2; record the exact
installed version and installation method). Inspect third-party install
scripts instead of piping them directly into a privileged shell. Do not
install or pull large models without approval and a disk/memory estimate.

OpenCode V2 documents ChatGPT sign-in as **one possible** external provider
option; actual entitlement, region, terms, usable models, provider costs and
account permissions must be verified by the operator. A subscription
does not imply unrestricted API access. Approve all potentially billable
model requests **before** Gate 1 or Gate 2. If no approved external model,
mark cloud and dual runs `BLOCKED`; local-only diagnostics may continue.

Ollama recommends a **64k+ context** for agent use; verify effective context,
tool-call support and VRAM/RAM impact on the actual model. Do not rebind
the unauthenticated Ollama listener to LAN or lower firewall restrictions.

## Disposable workspace setup (one immutable starting commit)

Do **not** run a reset or checkout of the live AI Lab worktree. From its
clean branch, after reviewing the commands:

```bash
cd /path/to/ai-lab
python3 experiments/multi-agent-e2e/verify_static.py
RUN_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ai-lab-e2e.XXXXXXXX")"
mkdir -p "$RUN_ROOT/seed" "$RUN_ROOT/evidence/raw"
cp -a experiments/multi-agent-e2e/fixture/. "$RUN_ROOT/seed/"
git -C "$RUN_ROOT/seed" init -q
git -C "$RUN_ROOT/seed" add .
git -C "$RUN_ROOT/seed" -c user.name="E2E Fixture" \
  -c user.email="fixture@example.invalid" commit -qm "fixture: known red baseline"
FIXTURE_BASE_SHA="$(git -C "$RUN_ROOT/seed" rev-parse HEAD)"
for case in cloud local dual; do
  git clone -q --no-hardlinks "$RUN_ROOT/seed" "$RUN_ROOT/$case"
done
printf 'RUN_ROOT=%s\nFIXTURE_BASE_SHA=%s\n' "$RUN_ROOT" "$FIXTURE_BASE_SHA"
```

Record the actual `RUN_ROOT` and `FIXTURE_BASE_SHA` in **private local**
notes. Each clone must start from the **same** commit, with one failing test:

```bash
cd "$RUN_ROOT/cloud"
git rev-parse HEAD
python3 -m unittest discover -s tests -v  # expected exit 1: exactly one failure
```

Use a *new OpenCode session for each clone*. The task is
`TASK.md`; **no modifications to TASK.md/tests/config** during a run.

## Gate 1 — independent solo baselines

Operator sets verified, permitted model IDs:

```bash
export PILOT_EXTERNAL_MODEL='provider/verified-external-model'
export PILOT_LOCAL_MODEL='ollama/qwen3-coder:30b'
```

**Replace placeholders only after Gate 0; do not invent provider IDs.**
Start cloud and local separately. Run **without `--auto`**, from the
respective disposable clones:

```bash
cd "$RUN_ROOT/cloud"
opencode run --standalone --agent pilot-solo --model "$PILOT_EXTERNAL_MODEL" \
  --format json "$(cat TASK.md)" > "$RUN_ROOT/evidence/raw/cloud.events.jsonl"
# Independently, after the agent finishes:
python3 -m unittest discover -s tests -v
git diff --check && git diff -- scheduler.py && git status --short

cd "$RUN_ROOT/local"
opencode run --standalone --agent pilot-solo --model "$PILOT_LOCAL_MODEL" \
  --format json "$(cat TASK.md)" > "$RUN_ROOT/evidence/raw/local.events.jsonl"
python3 -m unittest discover -s tests -v
git diff --check && git diff -- scheduler.py && git status --short
```

If a permission prompt cannot be handled in headless mode, use
interactive OpenCode for that exact clone and **record the mode**; never
bypass approval with `--auto`. The agent might return failure even when
tests pass: preserve the command exit code and separate test result.

## Gate 2 — explicit primary → local subagent → primary

Only after both solo baselines are assessed, and external calls approved:

```bash
cd "$RUN_ROOT/dual"
opencode run --standalone --agent pilot-primary --model "$PILOT_EXTERNAL_MODEL" \
  --format json "$(cat TASK.md)
Gate 2: invoke root-cause-reviewer BEFORE changing any file. Use its
reported analysis and then fix scheduler.py yourself. Report both
provider/model IDs and the delegation result." \
  > "$RUN_ROOT/evidence/raw/dual.events.jsonl"
python3 -m unittest discover -s tests -v
git diff --check && git diff -- scheduler.py && git status --short
```

**Do not assert multi-agent PASS from model-generated prose.** Identify
first-party event/session evidence of both model IDs, the child invocation,
parent/child linkage or equivalent, child result returned to primary, and
the subsequent primary write. If any required evidence is unavailable, report
`BLOCKED` or `NOT TESTED`, not PASS.

## Stock OpenCode tracing and result preservation

V2 CLI provides `run --format json` (NDJSON events),
`session list --format json` and `session export SESSION_ID --sanitize`.
For each run record the session ID from actual events/session list, then:

```bash
cd "$RUN_ROOT/dual"  # repeat for cloud/local
opencode session list --format json
opencode session export '<ACTUAL_SESSION_ID>' --sanitize \
  > "$RUN_ROOT/evidence/raw/dual.session.sanitized.json"
```

Check which metadata the installed CLI actually exports; `--sanitize`
does **not** authorize publication without manual inspection. Raw JSONL,
exports, terminal logs and personal paths stay under ignored/private
evidence directories. Commit only curated, sanitized excerpts (if needed),
the three status/exit-code records, model/provider identifiers, test
output summaries, timings, actual Git revisions and diff statistics
using `evidence/RESULTS.template.md`. Preserve original diagnostics locally
for reviewer inspection, rather than copying secrets into Git.

`PASS`: independent tests green AND only allowed diff; Gate 2 further
requires observed cross-model delegation + returned result.
`FAIL`: executed test or E2E produced incorrect/unsafe outcome.
`BLOCKED`: prerequisite, approval, availability or observation prevents
assessment. `NOT TESTED`: never executed. A passing reference fixture
does **not** count toward any runtime gate.

### Official documentation (reviewed 2026-10-27)

- OpenCode V2: https://opencode.ai/v2/docs/agents
- OpenCode V2 permissions: https://opencode.ai/v2/docs/permissions
- OpenCode V2 Ollama provider: https://opencode.ai/v2/docs/providers
- OpenCode V2 CLI: https://dev.opencode.ai/v2/docs/cli/commands
- OpenCode installation: https://opencode.ai/download
- Ollama/OpenCode: https://docs.ollama.com/integrations/opencode
