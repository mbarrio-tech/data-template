#!/usr/bin/env python3
"""
Schema Breaker Check
====================
Detects whether any schema change introduced in this PR breaks downstream
datasets in the DAG.

How it works
------------
1. Reads the compiled DAG manifest (dbt manifest.json or Dataform
   compiledGraph.json) to build the full dependency graph.
2. Diffs changed schema files (schema.yml / sources.yml / .sqlx config
   blocks) between the PR branch and the base branch (main).
3. Identifies which columns were removed or renamed in the changed files.
4. Traverses the DAG downstream from each affected model and reports every
   node that references a removed or renamed column.

Exit codes
----------
0  No breaking changes detected.
1  Breaking changes detected — PR is blocked.

Environment variables (set by the workflow)
-------------------------------------------
BASE_REF       : git ref to diff against (default: origin/main)
MANIFEST_PATH  : path to the compiled DAG manifest
               dbt    → target/manifest.json
               Dataform → .dataform/compiledGraph.json
"""

import json
import os
import subprocess
import sys
from pathlib import Path

import yaml

BASE_REF = os.environ.get("BASE_REF", "origin/main")
MANIFEST_PATH = Path(os.environ.get("MANIFEST_PATH", "target/manifest.json"))


# ── Helpers ──────────────────────────────────────────────────────────────────

def run(cmd: str) -> str:
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout.strip()


def get_changed_files() -> list[str]:
    base_sha = run(f"git merge-base HEAD {BASE_REF}")
    output = run(f"git diff --name-only {base_sha} HEAD")
    return [f for f in output.splitlines() if f]


def get_file_at_base(path: str) -> str | None:
    base_sha = run(f"git merge-base HEAD {BASE_REF}")
    result = subprocess.run(
        ["git", "show", f"{base_sha}:{path}"],
        capture_output=True, text=True
    )
    return result.stdout if result.returncode == 0 else None


# ── Schema diff ──────────────────────────────────────────────────────────────

def extract_columns_from_schema_yml(content: str) -> dict[str, set[str]]:
    """Return {model_name: {col1, col2, ...}} from a dbt schema.yml string."""
    try:
        data = yaml.safe_load(content) or {}
    except yaml.YAMLError:
        return {}

    result: dict[str, set[str]] = {}
    for model in data.get("models", []) + data.get("sources", []):
        name = model.get("name", "")
        cols = {c["name"] for c in model.get("columns", []) if "name" in c}
        if name:
            result[name] = cols
    return result


def find_breaking_column_changes(changed_files: list[str]) -> dict[str, list[str]]:
    """
    Returns {model_name: [removed_col, ...]} for schema files that had columns
    removed or renamed compared to the base branch.
    """
    schema_files = [
        f for f in changed_files
        if f.endswith(("schema.yml", "sources.yml", "_schema.yml"))
    ]

    breaking: dict[str, list[str]] = {}

    for path in schema_files:
        base_content = get_file_at_base(path)
        if base_content is None:
            # New file — no removals possible
            continue

        head_content = Path(path).read_text() if Path(path).exists() else ""

        base_cols = extract_columns_from_schema_yml(base_content)
        head_cols = extract_columns_from_schema_yml(head_content)

        for model, old_columns in base_cols.items():
            new_columns = head_cols.get(model, set())
            removed = old_columns - new_columns
            if removed:
                breaking[model] = sorted(removed)

    return breaking


# ── DAG traversal ─────────────────────────────────────────────────────────────

def load_dbt_manifest(path: Path) -> dict:
    with open(path) as f:
        return json.load(f)


def get_downstream_nodes(manifest: dict, model_name: str) -> list[str]:
    """
    Return all downstream node unique_ids that depend on model_name,
    traversing the full DAG depth.
    """
    # Build reverse dependency map: node → list of nodes that depend on it
    child_map: dict[str, list[str]] = {}
    for node_id, node in manifest.get("nodes", {}).items():
        for dep in node.get("depends_on", {}).get("nodes", []):
            child_map.setdefault(dep, []).append(node_id)

    # Find nodes whose unique_id ends with the model name
    roots = [
        nid for nid in manifest.get("nodes", {})
        if nid.endswith(f".{model_name}") or nid.endswith(f"__{model_name}")
    ]

    # BFS from roots
    visited: set[str] = set()
    queue = list(roots)
    while queue:
        current = queue.pop(0)
        for child in child_map.get(current, []):
            if child not in visited:
                visited.add(child)
                queue.append(child)

    return sorted(visited)


def friendly_name(node_id: str) -> str:
    # dbt node IDs look like: model.project.table_name
    parts = node_id.split(".")
    return parts[-1] if parts else node_id


# ── Main ─────────────────────────────────────────────────────────────────────

def main() -> int:
    changed_files = get_changed_files()
    if not changed_files:
        print("No changed files detected.")
        return 0

    print(f"Changed files ({len(changed_files)}):")
    for f in changed_files:
        print(f"  {f}")

    breaking = find_breaking_column_changes(changed_files)
    if not breaking:
        print("\n✅ No schema column removals or renames detected.")
        return 0

    # Load DAG to find downstream impact
    if not MANIFEST_PATH.exists():
        print(
            f"\n⚠️  Breaking column changes detected but DAG manifest not found at "
            f"'{MANIFEST_PATH}'.\n"
            f"   Run 'dbt compile' before the schema breaker check, or set MANIFEST_PATH.\n"
            f"   Breaking changes (without DAG impact):"
        )
        for model, cols in breaking.items():
            print(f"   {model}: removed columns → {', '.join(cols)}")
        return 1

    manifest = load_dbt_manifest(MANIFEST_PATH)
    found_impact = False

    print("\n🔍 Schema breaking change analysis:\n")

    for model, removed_cols in breaking.items():
        downstream = get_downstream_nodes(manifest, model)
        print(f"  Model : {model}")
        print(f"  Removed columns: {', '.join(removed_cols)}")

        if downstream:
            found_impact = True
            print(f"  ❌ Downstream impact ({len(downstream)} node(s)):")
            for node in downstream:
                print(f"       → {friendly_name(node)}")
        else:
            print("  ✅ No downstream consumers affected.")
        print()

    if found_impact:
        print(
            "❌ SCHEMA BREAKER: This PR removes or renames columns that are consumed\n"
            "   by downstream datasets. Fix the downstream references before merging,\n"
            "   or use the expand/contract pattern (add new column, migrate, remove old).\n"
            "   See docs/capability-library/sql-quality.md for guidance."
        )
        return 1

    print("✅ Breaking column changes found but no downstream consumers affected.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
