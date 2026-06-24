---
name: project-inception
description: Use when this repository has just been cloned and the project has not yet been bootstrapped — placeholder values are still present throughout the doc files.
---

# Project Inception Skill

## Overview

Bootstraps a cloned `project-template` repository into a real project by populating all documentation placeholders from a validated Intent Document provided by product.

## When to Use

- You have just cloned the `project-template` repository
- `CLAUDE.md` or `docs/polaris/polaris.md` still contains `[Project Name]` or other placeholder text
- The team is starting a new engagement and has a validated Intent Document from product ready to process

## Core Pattern

1. **Read `docs/polaris/polaris.md`** — confirm it still has placeholder content
2. **Invoke the inception agent** — say "Run the inception agent"
3. **Answer the 8 questions** — project name, client, team lead, team members, repository URL, tech stack, constraints, Intent Document
4. **Review and confirm** each populated file section before the agent moves to the next
5. **Commit** with: `git commit -m "chore: project inception — [Project Name]"`

## What Gets Populated

| File | What Changes |
|---|---|
| `docs/polaris/polaris.md` | All placeholder sections, frontmatter version/status/owner/date |
| `docs/architecture/architecture.md` | Tech stack table, frontmatter |
| `CLAUDE.md` | Project name, client, team, summary, tech stack, constraints |

## Common Mistakes

- **Running without the Intent Document** — do not run inception without the validated Intent Document from product. Guessing deliverables causes misalignment that takes sprints to fix.
- **Partial inception** — if the agent is interrupted, re-run it from the beginning. Partial population looks complete but is not.
- **Not committing** — the inception commit is the baseline for the entire project history. Missing it makes the git log impossible to interpret.
