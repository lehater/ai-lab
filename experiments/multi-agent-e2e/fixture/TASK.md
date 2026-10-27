# Task — half-open interval bug

Fix the smallest possible defect in `scheduler.py`: `intervals_overlap`
incorrectly reports overlap for two valid half-open intervals that merely
touch at an endpoint. Intervals are `[start, end)`; endpoint equality means
**no** shared instant. Keep existing validation and all other behavior.

Acceptance:
- `python3 -m unittest discover -s tests -v` passes all six tests.
- Only `scheduler.py` changes (no edits to tests, TASK.md or config).
- Explain the root cause and report independent test evidence.
- No external packages, network access, Git push or other repo changes.

Gate 1 (solo): solve with a single primary agent, do NOT invoke a subagent.
Gate 2 (dual): explicitly invoke the `root-cause-reviewer` subagent before
editing, receive its analysis, and then make the smallest correction yourself.
