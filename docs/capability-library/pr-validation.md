---
version: 1.1
last-updated: 2026-06-25
owner: "[Tech Lead]"
domain: "pr-validation"
applies-to: "Every pull request targeting the main branch that touches SQL, Terraform, or schema files"
---

# Capability: PR Validation

## Summary

Three automated checks run on every pull request to main before merge is allowed.
They are read-only — nothing is deployed, no warehouse is written to. The checks
validate what a human reviewer would catch if they had unlimited time and a complete
picture of the DAG.

---

## Hard Gate

<HARD-GATE>
A PR cannot be merged into main until all three validation checks pass (or are explicitly
overridden by the Tech Lead with a documented reason). These checks are not advisory —
they are merge requirements.
</HARD-GATE>

---

## Check 1: SQL Formatting (SQLFluff)

**Mechanism:** GitHub Actions workflow job `formatting`
**Blocks merge:** Yes — any SQLFluff violation fails the job
**Scope:** Every `.sql` and `.sqlx` file changed in the PR

### What it does

Runs `sqlfluff lint` against every SQL file changed in the PR using the project's
`.sqlfluff` config. Reports violations as GitHub annotations inline on the PR diff —
each one links directly to the file and line number.

### What it catches

Everything in the lint rules from `docs/capability-library/sql-quality.md`:

- `SELECT *` in production queries
- Unqualified table references
- Wrong capitalisation (`select` instead of `SELECT`)
- Missing `AS` on aliases
- `GROUP BY` / `ORDER BY` using positional integers
- Dead CTEs (defined but never referenced)

### How to fix failures

```bash
# See exactly what the workflow sees
sqlfluff lint path/to/changed_file.sql

# Auto-fix anything SQLFluff can correct automatically
sqlfluff fix path/to/changed_file.sql
```

Each annotation in the PR includes the rule ID. Look it up in the
[SQLFluff rule reference](https://docs.sqlfluff.com/en/stable/rules.html)
for the correct pattern.

---

## Check 2: Schema Breaker

**Mechanism:** GitHub Actions workflow job `schema-breaker`
**Blocks merge:** Yes — any detected breaking downstream impact fails the job
**Scope:** `schema.yml`, `sources.yml`, and `.sqlx` config blocks changed in the PR
**Script:** `scripts/check_schema_breaking.py`

### What it does

1. Diffs every schema file changed in the PR against `main`
2. Identifies columns that were **removed or renamed**
3. Loads the compiled DAG manifest (`target/manifest.json` for dbt,
   `.dataform/compiledGraph.json` for Dataform)
4. BFS-traverses the full DAG downstream from every affected model
5. Reports every downstream node that would break

### What it catches

A column renamed or dropped without checking downstream consumers.
Even if the immediate model compiles, any downstream model that `SELECT`s the old
column name will fail at runtime — often silently producing nulls.

```
✗ fact_orders: removed columns → customer_segment
  Downstream impact (3 nodes):
    → mart_revenue_by_segment
    → report_customer_cohort
    → ml_feature_store_weekly
```

### How to fix failures

The check does not prohibit removing columns — it requires doing it safely:

1. **Do not remove the column in this PR.** First update all downstream consumers.
2. **Update downstream models first**, then remove the column in a follow-up PR.
3. **Use expand/contract** — if renaming, add the new column name alongside the old
   one and migrate downstream models over two PRs.

### Prerequisites

Requires a compiled DAG manifest. Without it the script reports column removals
but cannot determine downstream impact (and still fails so the author verifies manually).

- **dbt:** add a `dbt compile` step before the schema-breaker job, or cache the manifest
- **Dataform:** set the `DAG_MANIFEST_PATH` repository variable to `.dataform/compiledGraph.json`
  and add a `dataform compile` step

---

## Check 3: AI PR Review (GitHub Copilot)

**Mechanism:** GitHub Copilot automatic code review — native GitHub feature, no workflow job required
**Blocks merge:** Configurable via branch protection ruleset
**Scope:** All changed files that Copilot can analyse
**Instructions:** `.github/copilot-code-review-instructions.md`

### What it does

GitHub Copilot reviews the PR automatically when it is opened or updated and posts
inline comments and a summary directly in the GitHub PR UI — the same experience as a
human reviewer leaving comments on the diff.

The review is guided by `.github/copilot-code-review-instructions.md`, which encodes
the project's SQL quality rules, spec testing requirements, data quality check rules,
and Terraform security controls. Copilot applies those rules to every file it reviews.

### What it catches

- `SELECT *`, missing filters before joins, `ORDER BY` without `LIMIT` in CTEs
- Complex SQL logic (window functions, UDFs, multi-branch CASE) without a SPEC file
- Missing `not_null`, `unique`, or `accepted_values` tests on new or modified models
- Terraform resources with public access, over-privileged IAM, or hardcoded secrets
- General code quality issues: missing error handling, unclear naming

### How to set it up (one-time)

#### Step 1 — Enable Copilot code review on the repository

Go to your repository on GitHub:

```
Settings → Copilot → Code review
→ Toggle "Automatically request Copilot review on new pull requests" → ON
```

This makes Copilot a reviewer on every PR automatically, without anyone needing to
manually request it.

#### Step 2 — Set the review effort level

On the same settings page:

```
Settings → Copilot → Code review → Review effort level
```

Choose **Medium** for most projects (deeper analysis, uses more Actions minutes).
Use **Low** only if CI costs are a concern.

#### Step 3 — Confirm the instructions file is present

The file `.github/copilot-code-review-instructions.md` is already committed in this
repo. Copilot picks it up automatically — no additional configuration needed.

Verify it is present:

```bash
cat .github/copilot-code-review-instructions.md
```

If you want to add project-specific rules (e.g. a custom UDF list, specific table
naming conventions), edit that file. The character limit has been removed as of
June 2026 — write as much as needed.

#### Step 4 — Make Copilot review a required check (optional but recommended)

To block merge until Copilot finishes its review:

```
Settings → Rules → Rulesets → New branch ruleset
→ Target: main
→ Required status checks → Add "Copilot code review"
→ Enforcement: Active
```

Without this, the review runs and comments are posted, but merge is not blocked.
**Start without blocking** to calibrate signal quality, then enable blocking once the
team trusts the review.

#### Step 5 — Confirm plan eligibility

Copilot code review is available on **Copilot Pro, Pro+, or Max** plans, and to
organisation members when enabled by an enterprise admin. Confirm your plan covers it
before enabling.

### What Copilot cannot do

Copilot reviews the diff — it cannot execute the SQL, inspect live warehouse state,
check row counts, or reason about production data volumes. It catches structural and
pattern violations well. It does not replace the schema breaker for DAG-level impact
analysis or SQLFluff for exhaustive style checking.

---

## Setup Checklist (one-time, at project inception)

- [ ] Confirm Copilot plan eligibility (Pro / Pro+ / Max, or enterprise org setting)
- [ ] Enable automatic Copilot review: `Settings → Copilot → Code review → ON`
- [ ] Set review effort level to **Medium**
- [ ] Verify `.github/copilot-code-review-instructions.md` is present
- [ ] Confirm `.sqlfluff` exists at repo root with the correct dialect
- [ ] Add `dbt compile` or `dataform compile` to CI setup, OR set `DAG_MANIFEST_PATH`
- [ ] Configure branch protection ruleset on `main` requiring:
  - `formatting` job (SQLFluff) — always block
  - `schema-breaker` job — always block
  - Copilot code review — block once signal quality is confirmed

---

## Workflow Trigger

The GitHub Actions workflow (checks 1 and 2) runs on `pull_request` targeting `main`
and only when files that affect data quality or security change:

```
**.sql  **.sqlx  models/**  specs/**  *.tf  **schema.yml  **sources.yml
```

PRs that touch only documentation or non-data code skip the workflow entirely.
Copilot review runs independently of this trigger — it fires on every PR regardless
of which files changed.

---

## Files

| File | Purpose |
|---|---|
| `.github/workflows/pr-validation.yml` | GitHub Actions — SQLFluff and schema breaker jobs |
| `.github/copilot-code-review-instructions.md` | Rules Copilot enforces on every PR review |
| `scripts/check_schema_breaking.py` | Schema breaker — diffs schema files and traverses the DAG |
| `.sqlfluff` | SQLFluff config used by the formatting check |
