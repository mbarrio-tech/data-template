---
name: requesting-code-review
description: Use when completing a feature, after each task in subagent-driven development, or before merging to main — dispatches the code-reviewer agent with precisely crafted context.
---

# Requesting Code Review

Dispatch the `code-reviewer` agent to catch issues before they compound. The reviewer gets precisely crafted context — never your session history. This keeps the review focused on the work product, not your thought process.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After completing a feature branch, before opening a PR
- After each task when using `subagent-driven-development`
- Before any merge to main

**Valuable but optional:**
- When stuck — a fresh perspective finds what you stopped seeing
- Before a large refactor — establish a quality baseline
- After fixing a complex bug — verify the fix did not introduce new issues

## How to Request

### 1. Get the commit range

```bash
# From last commit on base branch to HEAD
BASE_SHA=$(git merge-base HEAD main)
HEAD_SHA=$(git rev-parse HEAD)

# Or for a single task review (last commit only)
BASE_SHA=$(git rev-parse HEAD~1)
HEAD_SHA=$(git rev-parse HEAD)
```

### 2. Generate the diff

```bash
git diff $BASE_SHA $HEAD_SHA
```

### 3. Dispatch the code-reviewer agent

In Claude Code, say: **"Run the code-reviewer agent"**

Provide the agent with:
- What was implemented (feature name, which plan task)
- The plan or requirements it should have followed
- The git diff (`git diff $BASE_SHA $HEAD_SHA`)
- The commit range (BASE_SHA and HEAD_SHA)

### 4. Act on feedback

| Severity | Action |
|---|---|
| Critical | Fix immediately before continuing any other work |
| Important | Fix in current PR before merge |
| Suggestion | Log for later or address if quick |

If you disagree with a finding, explain your reasoning — the reviewer may be wrong. Push back with evidence.

## Common Mistakes

- Sending the reviewer your full session context — give them only the diff and the requirements
- Skipping review to save time — review catches issues that are cheap to fix now and expensive to fix later
- Ignoring Critical findings — they exist for a reason
- Running review after the PR is already merged — review before merge
