#!/usr/bin/env python3
"""Read-only Stage A evidence preflight. Never print evidence values or secrets.

Not a substitute for a human review before publishing to a public Git repo.
Uses Python 3 stdlib; no network, Git mutations, or external dependencies.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

DIR = Path(__file__).resolve().parents[1] / "evidence" / "2026-10-22-stage-a"
NAMES = ("workflow-before.json", "workflow-after.json", "results.json")
KEY_RE = re.compile(
    r"(?:^|[_-])(access[_-]?token|api[_-]?key|bearer|client[_-]?secret|"
    r"credential(?:s)?|password|private[_-]?key|session[_-]?token|"
    r"authorization|encryption[_-]?key)(?:$|[_-])",
    re.IGNORECASE,
)
VALUE_RE = re.compile(
    r"-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----|"
    r"\b(?:sk-[A-Za-z0-9_-]{16,}|github_pat_[A-Za-z0-9_]{16,}|"
    r"gh[opurs]_[A-Za-z0-9]{16,}|xox[baprs]-[A-Za-z0-9-]{16,})\b|"
    r"\bBearer\s+[A-Za-z0-9_+./=-]{12,}|"
    r"(?i:https?://)[^\s/@]+:[^\s/@]+@|"
    r"\b(?:N8N_ENCRYPTION_KEY|AI_LAB_N8N_MCP_TOKEN)\s*[=:]\s*\S+",
)


def review_values(value: object) -> tuple[int, int]:
    """Return counts only: sensitive-looking populated keys, token-shaped values."""
    suspicious_keys = 0
    suspicious_values = 0

    def walk(node: object) -> None:
        nonlocal suspicious_keys, suspicious_values
        if isinstance(node, dict):
            for key, val in node.items():
                if isinstance(key, str) and KEY_RE.search(key) and val not in (None, "", [], {}):
                    suspicious_keys += 1
                walk(val)
        elif isinstance(node, list):
            for val in node:
                walk(val)
        elif isinstance(node, str) and VALUE_RE.search(node):
            suspicious_values += 1

    walk(value)
    return suspicious_keys, suspicious_values


def workflow(value: object) -> dict | None:
    """Locate standard n8n workflow payload with nodes and connections."""
    if isinstance(value, dict):
        if isinstance(value.get("nodes"), list) and isinstance(value.get("connections"), dict):
            return value
        for key in ("workflow", "data", "result", "details"):
            if key in value:
                found = workflow(value[key])
                if found is not None:
                    return found
    return None


def main() -> int:
    if not DIR.is_dir():
        print("FAIL: Stage A evidence directory missing")
        return 1

    data: dict[str, object] = {}
    fail = False
    for name in NAMES:
        try:
            data[name] = json.loads((DIR / name).read_text(encoding="utf-8"))
            print(f"JSON: {name}: valid")
        except (OSError, ValueError, UnicodeError) as exc:
            print(f"FAIL: {name}: unreadable or invalid JSON ({type(exc).__name__})")
            fail = True

    readme = DIR / "README.md"
    if readme.is_file():
        print("README: present")
        try:
            readme_text = readme.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            print("FAIL: README unreadable")
            fail = True
            readme_text = ""
    else:
        print("FAIL: README missing")
        fail = True
        readme_text = ""

    for name, obj in data.items():
        flagged_keys, flagged_values = review_values(obj)
        print(f"Secret indicators: {name}: populated_sensitive_fields={flagged_keys}, token_patterns={flagged_values}")
        if flagged_keys or flagged_values:
            fail = True

    if readme_text:
        hits = len(VALUE_RE.findall(readme_text))
        print(f"Secret indicators: README.md: token_patterns={hits}")
        if hits:
            fail = True

    if "workflow-before.json" in data and "workflow-after.json" in data:
        before = workflow(data["workflow-before.json"])
        after = workflow(data["workflow-after.json"])
        if before is None or after is None:
            print("REVIEW: workflow nodes/connections not found in expected JSON shape")
        else:
            before_nodes, after_nodes = before["nodes"], after["nodes"]
            same_identity = (
                [(n.get("id"), n.get("name"), n.get("type")) for n in before_nodes]
                == [(n.get("id"), n.get("name"), n.get("type")) for n in after_nodes]
            )
            same_graph = before["connections"] == after["connections"]
            changed_parameters = (
                sum(x.get("parameters") != y.get("parameters") for x, y in zip(before_nodes, after_nodes))
                if same_identity else None
            )
            same_workflow_id = (
                before.get("id") == after.get("id") if before.get("id") and after.get("id") else None
            )
            print(f"Workflow comparison: node_identity_unchanged={same_identity}; "
                  f"connections_unchanged={same_graph}; parameters_changed_nodes={changed_parameters}; "
                  f"workflow_id_unchanged={same_workflow_id}")
            if not same_identity or not same_graph or changed_parameters != 1 or same_workflow_id is False:
                fail = True

    if fail:
        print("RESULT: REVIEW REQUIRED. Do not commit/push raw files without manual inspection.")
        return 1
    print("RESULT: automated preflight passed; MANUAL secret/content review still required before public Git push.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
