#!/usr/bin/env python3
"""Dependency-free static configuration + red/green fixture contract check."""
import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent
FIXTURE = ROOT / "fixture"
TEST_CMD = [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"]


def check() -> None:
    config = json.loads((FIXTURE / "opencode.json").read_text(encoding="utf-8"))
    assert config["$schema"] == "https://opencode.ai/config.json"
    assert "provider" not in config and "agent" not in config
    assert config["providers"]["ollama"]["settings"]["baseURL"] == "http://127.0.0.1:11434/v1"
    agents = config["agents"]
    assert set(agents) == {"pilot-solo", "pilot-primary", "root-cause-reviewer"}
    reviewer = agents["root-cause-reviewer"]
    assert reviewer["model"].startswith("ollama/")
    assert reviewer["mode"] == "subagent"
    # Child policy denies *all* actions, then permits local read-only discovery.
    child_rules = reviewer["permissions"]
    assert child_rules[0] == {"action": "*", "resource": "*", "effect": "deny"}, child_rules
    for rule in child_rules[1:]:
        assert rule["effect"] == "allow" and rule["action"] in ("read", "glob", "grep"), rule
    assert {rule["action"] for rule in child_rules[1:]} == {"read", "glob", "grep"}
    assert {"action": "subagent", "resource": "*", "effect": "deny"} in agents["pilot-solo"]["permissions"]
    dual_rules = agents["pilot-primary"]["permissions"]
    assert dual_rules[-1] == {"action": "subagent", "resource": "root-cause-reviewer", "effect": "allow"}
    assert {"action": "edit", "resource": "scheduler.py", "effect": "allow"} in config["permissions"]
    assert {"action": "external_directory", "resource": "*", "effect": "deny"} in config["permissions"]
    assert {"action": "subagent", "resource": "*", "effect": "deny"} in config["permissions"]

    original = (FIXTURE / "scheduler.py").read_text(encoding="utf-8")
    faulty = "b_start <= a_end"
    corrected = "b_start < a_end"
    assert original.count(faulty) == 1
    assert corrected not in original
    with tempfile.TemporaryDirectory(prefix="multi-agent-e2e-static-") as td:
        root = Path(td)
        (root / "tests").mkdir()
        (root / "scheduler.py").write_text(original, encoding="utf-8")
        (root / "tests" / "test_scheduler.py").write_text(
            (FIXTURE / "tests" / "test_scheduler.py").read_text(encoding="utf-8"),
            encoding="utf-8",
        )
        red = subprocess.run(TEST_CMD, cwd=root, capture_output=True, text=True)
        assert red.returncode != 0, f"baseline unexpectedly green:\n{red.stdout}\n{red.stderr}"
        assert "FAILED (failures=1)" in red.stderr, red.stderr
        assert "Ran 6 tests" in red.stderr, red.stderr
        (root / "scheduler.py").write_text(original.replace(faulty, corrected), encoding="utf-8")
        green = subprocess.run(TEST_CMD, cwd=root, capture_output=True, text=True)
        assert green.returncode == 0, f"reference correction failed:\n{green.stdout}\n{green.stderr}"
        assert "Ran 6 tests" in green.stderr, green.stderr
    print("STATIC PASS: JSON contract; fixture RED (1 expected failure); reference GREEN (6 tests)")


if __name__ == "__main__":
    try:
        check()
    except (AssertionError, KeyError, OSError, ValueError) as exc:
        print(f"STATIC FAIL: {exc}", file=sys.stderr)
        sys.exit(1)
