---
name: updating-docs
description: Use when a living documentation file needs to be updated due to a new decision, a change in requirements, an architectural change, or a new security finding.
---

# Updating Docs Skill

## Overview

Maintains the integrity of the project's living documentation by following a consistent update and version-bumping pattern. Ensures the AI context files stay accurate and the team has a reliable source of truth.

## When to Use

- A new architectural decision has been made → update `docs/architecture/architecture.md`
- Client requirements have changed → use the `requirements-analyst` agent first, then update `docs/polaris/polaris.md`
- A security control has been added, changed, or a new compliance requirement identified → update `docs/security/security.md`
- Test strategy, tooling, or coverage targets have changed → update `docs/test/test.md`

## Core Pattern

1. **Identify which doc** needs updating based on the type of change
2. **Open and read** the relevant section before making any edits
3. **Make the change** — be specific and factual, no vague language
4. **Bump the `version`** in the YAML frontmatter using the rules below
5. **Update `last-updated`** to today's date in the frontmatter (YYYY-MM-DD)
6. **Add a row** to the in-file Change Log table at the bottom of the doc
7. **Commit** with a descriptive conventional commit message:
   ```
   docs(polaris): add acceptance criteria for deliverable 3
   docs(architecture): add ADR-002 — switch database from SQL Server to PostgreSQL
   docs(security): add GDPR data residency requirement to compliance section
   ```

## Frontmatter Bump Rules

| Change Type | Version Bump | Status Effect |
|---|---|---|
| Minor addition, clarification, typo fix | Patch (x.y → x.y+1) | Keep current status |
| New deliverable, decision reversal, scope change | Minor (x.y → x+1.0) | Reset to `draft` if was `approved` |
| Stakeholder has formally approved the document | No version change | `draft` → `approved` |
| Document superseded by a newer version | No version change | `approved` → `superseded` |

## Common Mistakes

- **Forgetting the frontmatter version bump** — unchanged version numbers make it impossible for the team or AI tools to tell whether a doc is current.
- **Vague change log entry** — "updated section" is not useful. Write specifically: "added acceptance criterion: system must process requests within 2s at the 99th percentile."
- **Not committing** — doc changes without a commit are invisible to the team, invisible to AI tools, and cannot be referenced in a code review or retrospective.
