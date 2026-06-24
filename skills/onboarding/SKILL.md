---
name: onboarding
description: Use when a new developer, analyst, or other team member has joined the project and needs to understand what is being built, set up their environment, and receive their first task.
---

# Onboarding Skill

## Overview

Guides a new team member from zero context to ready for their first task, using the project's living documentation as the source of truth throughout.

## When to Use

- A new developer, analyst, designer, or other contributor has joined the project
- A returning team member has been away and needs to catch up on what changed
- An external contractor is being onboarded to the engagement

## Core Pattern

1. **Invoke the onboarding-guide agent** — say "Run the onboarding guide for [Name]"
2. The agent walks through: `polaris.md` → `architecture.md` → `security.md` → `test.md` → dev setup → first task
3. **Confirm understanding at each phase** — the agent will ask; do not advance until the new member confirms
4. **Dev environment** — have a senior developer available for local environment questions
5. **Assign a first task** before closing the session — never leave a new member without a concrete starting point

## What the Onboarding Covers

| Phase | Source | Purpose |
|---|---|---|
| Project context | `docs/polaris/polaris.md` | What are we building and why |
| Architecture | `docs/architecture/architecture.md` | How it is built |
| Security rules | `docs/security/security.md` | Non-negotiable guardrails |
| Testing expectations | `docs/test/test.md` | How and what to test |
| Dev setup | Team lead + README | Local environment running |
| First task | Backlog | Clear starting point |

## Common Mistakes

- **Skipping security.md** — every new team member must read and confirm the security rules before writing any code. Non-negotiable.
- **No dev environment validation** — do not close the onboarding session until the new member confirms tests pass locally.
- **No first task assigned** — a new team member without a clear first task will be unproductive and disoriented for days.
