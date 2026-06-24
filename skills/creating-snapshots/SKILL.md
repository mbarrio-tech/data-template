---
name: creating-snapshots
description: Use when a living document has reached an approved milestone baseline and a versioned snapshot needs to be preserved — at sprint end, milestone approval, or formal stakeholder sign-off.
---

# Creating Snapshots Skill

## Overview

Creates a point-in-time copy of a living document in its `archive/` subfolder and marks the milestone in Git. The living doc keeps its current filename; the archive holds the immutable historical record.

## When to Use

- End of a sprint and the relevant document has been reviewed and approved by the team lead
- A stakeholder has formally signed off on a document baseline
- A major milestone has been reached (M1 approval, go-live, end of a project phase)
- Immediately before a significant change that will supersede the current baseline

## Core Pattern

For each document to snapshot, follow these exact steps:

### Step 1: Copy the file to the archive folder

```
docs/polaris/polaris.md        →  docs/polaris/archive/YYYY-MM-DD.md
docs/architecture/architecture.md  →  docs/architecture/archive/YYYY-MM-DD.md
docs/security/security.md      →  docs/security/archive/YYYY-MM-DD.md
docs/test/test.md              →  docs/test/archive/YYYY-MM-DD.md
```

Use today's date in ISO format (e.g. `2026-03-31.md`).

### Step 2: Update the living doc frontmatter (not the archive copy)

If a stakeholder has formally signed off, set `status: approved`.

### Step 3: Commit the archive copy

```bash
git add docs/<area>/archive/YYYY-MM-DD.md
git commit -m "docs(<area>): snapshot v[version] — [milestone name]"
```

Example: `docs(polaris): snapshot v1.2 — sprint 2 approval`

### Step 4: Create a Git tag

```bash
git tag [milestone]-[doc]-approved
```

Example: `git tag sprint-2-polaris-approved`

### Step 5: Push everything including tags

```bash
git push
git push --tags
```

### Step 6: Add an entry to CHANGELOG.md

```markdown
## [Milestone Name] - YYYY-MM-DD

### Snapshot
- docs/polaris: v[version] approved — [brief description of what was approved]
```

## Naming Convention

| Component | Format | Example |
|---|---|---|
| Archive file name | `YYYY-MM-DD.md` | `2026-03-31.md` |
| Git tag | `[milestone]-[doc]-approved` | `sprint-2-polaris-approved` |
| Commit message | `docs([area]): snapshot v[n] — [milestone]` | `docs(polaris): snapshot v1.2 — sprint 2 approval` |

## Common Mistakes

- **Snapshotting an unreviewed doc** — always get explicit team lead or stakeholder confirmation before setting `status: approved`. Status is a trust signal for the entire team and AI tools.
- **Forgetting `git push --tags`** — tags are not pushed automatically with `git push`. They will be missing from the remote repository until you push them explicitly.
- **Editing the archive copy** — archive files are immutable records. If a correction is needed, update the living doc and create a new snapshot. Never modify an archived file.
