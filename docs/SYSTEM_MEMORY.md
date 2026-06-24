---
version: 1.0
status: active
last-updated: YYYY-MM-DD
owner: "[Orchestrator + Tech Lead]"
idf-ref: "Section 07 — Artifacts"
---

# System Memory

> **The single file every agent reads at the start of every session.**
> Populated during inception. Updated by the Orchestrator agent after every cycle close.
> Governed by the Tech Lead — reviewed at every Context Reset.
>
> A stale entry here is worse than no entry. Agents trust this file completely.
> When in doubt, remove. Use `git log docs/SYSTEM_MEMORY.md` to recover anything removed.

<!-- IDF NOTE: This file maps to SYSTEM_MEMORY.md in IDF v7.11 Section 07. -->

---

## Project Identity

| Field | Value |
|---|---|
| **Project** | [Project Name] |
| **Client** | [Client Name] |
| **Repository** | [Repository URL] |
| **Current Cycle** | 0 |
| **Last Context Reset** | YYYY-MM-DD |

---

## Current Stack

> Mirrors docs/architecture/architecture.md. Update here when a change is confirmed in production.

| Layer | Technology | Version | Notes |
|---|---|---|---|
| Language | [e.g. TypeScript] | [e.g. 5.4] | |
| Framework | [e.g. Next.js] | [e.g. 14] | |
| Database | [e.g. PostgreSQL] | [e.g. 16] | |
| Hosting | [e.g. AWS / GCP / Azure — defined at inception] | — | |
| CI/CD | [e.g. GitHub Actions / GitLab CI / Azure DevOps — defined at inception] | — | |

---

## Folder Structure

> Top-level only. Update when a new significant folder is created.

```
[Populated during inception — list top-level folders and their purpose]
```

---

## Run Commands

> Exact commands to build, test, and run the project locally.

```bash
# Install
[command]

# Run locally
[command]

# Run tests
[command]

# Build
[command]
```

---

## Architectural Decisions in Force

> Short, declarative statements. One line each. If a decision is reversed, remove it.
> For detailed ADRs, see docs/architecture/architecture.md.

- [e.g. All API endpoints require JWT authentication]
- [e.g. No direct database access from frontend — all through API layer]
- [e.g. All UI components use the design system from [package]]
- [e.g. Feature flags are required on all user-visible changes]

---

## Known Open Risks

> Decisions or design choices known to be fragile. Each has a mitigation in place but is not yet fully resolved.
> Remove a row when the risk is resolved. Cap at 5 active risks — if more accumulate, schedule a Context Reset.

| Risk | Area | Mitigation in Place | Target Resolution | Owner |
|---|---|---|---|---|
| *(none)* | — | — | — | — |

---

## Environment Map

> Exact environment details. Update when a new environment is provisioned or URLs change.

| Environment | Purpose | URL / Endpoint | Deploy Access | Promotion Path |
|---|---|---|---|---|
| Local | Dev + unit tests | localhost | All developers | → Staging |
| Staging | Integration + E2E | [URL] | Dev + DevOps | → Production |
| Production | Live users | [URL] | DevOps + Lead | — |

---

## Active Conventions

> Patterns the team always follows. If Builders keep getting these wrong, encode in capability-library instead.

- Commit format: `type(scope): description` (conventional commits)
- Branch naming: `[type]/[ticket-id]-[short-description]`
- PR requirement: All changes go through PRs — no direct commits to main
- Test requirement: Tests committed with the code, not as a follow-up
- Flag requirement: All user-visible changes behind a feature flag (IDF R3)

---

## Feature Governance Registry

> Every feature flag and its current lifecycle state.
> States: `Pending-OFF` → `Live-ON` → `Dead-OFF`
> Dead-OFF flags must be removed at the next Context Reset.

| Flag Name | State | Cycle | Owner | Activated | Notes |
|---|---|---|---|---|---|
| *(none yet)* | — | — | — | — | — |

---

## Cycle Log

> Chronological record of what was built. Written by Orchestrator at cycle close.
> This is the temporal memory the docs/ folder does not have.

| Cycle | Date | Intent Summary | What Shipped | Flag | Outcome |
|---|---|---|---|---|---|
| *(inception)* | YYYY-MM-DD | Project bootstrapped | Template files populated | — | Complete |

---

## Known Patterns and Anti-Patterns

> Patterns the team has discovered. Populate through Capability Harvest signal events.
> Full capability files live in docs/capability-library/.

| Pattern | Category | Status | Capability File |
|---|---|---|---|
| *(none yet — harvest through normal cycles)* | — | — | — |

---

## Provisional Entries

> Entries written by Orchestrator that have not yet been reviewed by the Tech Lead.
> All provisional entries must be reviewed at the next Context Reset.

| Entry | Added Cycle | Type |
|---|---|---|
| *(none)* | — | — |
