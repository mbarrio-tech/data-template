---
version: 1.0
status: draft
last-updated: YYYY-MM-DD
owner: "[Tech Lead]"
---

# Architecture

> Living document for tech stack, system components, data flows, and design decisions.
> Update when architectural decisions change: bump `version` and add a row to the Design Decisions Log.

## Tech Stack

| Layer | Technology | Version | Notes |
|---|---|---|---|
| Language | [e.g. C# / Python / TypeScript] | [version] | |
| Framework | [e.g. ASP.NET Core / FastAPI] | [version] | |
| Database | [e.g. SQL Server / PostgreSQL] | [version] | |
| AI / LLM | [e.g. OpenAI GPT-4o / AWS Bedrock / Google Gemini] | | |
| Hosting | [e.g. AWS ECS / GCP Cloud Run / Azure App Service — defined at inception] | | |
| CI/CD | [e.g. GitHub Actions / GitLab CI / Azure DevOps — defined at inception] | | |

## System Components

### [Component 1 Name]

**Responsibility:** [Single clear purpose of this component]
**Technology:** [Stack used]
**Interfaces:** [What it receives / exposes]

---

### [Component 2 Name]

**Responsibility:** [Single clear purpose]
**Technology:** [Stack used]
**Interfaces:** [What it receives / exposes]

---

## Data Flows

### [Flow Name, e.g. User Request to AI Response]

```
[Actor] → [Component A] → [Component B] → [External Service] → [Response]
```

[Brief description of the flow and any important details]

---

## Design Decisions Log (ADR)

| ID | Decision | Date | Rationale | Alternatives Considered |
|---|---|---|---|---|
| ADR-001 | [Decision made] | YYYY-MM-DD | [Why this was the right choice] | [What else was evaluated] |

## Non-Functional Requirements

| Requirement | Target | Measurement Approach |
|---|---|---|
| Availability | 99.9% | Cloud provider monitoring alerts |
| Response time | < 2s p95 | APM tooling — defined at inception |
| Scalability | [Target concurrent users] | Load testing |

## Data Migration Strategy

> Update this section when the project's migration tooling or pattern is confirmed.

**Pattern:** Expand/Contract — every schema change is split into two migrations across separate cycles.

- **Expand** (Cycle N): add new structure without removing old (new column, new table)
- **Contract** (Cycle N+1): remove old structure after code no longer references it

**Tooling:** [e.g. EF Core Migrations / Flyway / Alembic / Liquibase — populated at inception]

**Rules:**
- Migrations are forward-only in production — `Down()` is for local dev only
- Every migration must be idempotent (safe to run twice)
- Migration tasks are sequenced first in every orchestrator task list
- Schema changes are never behind feature flags — they are direct deployments

For step-by-step guidance, invoke: `Use the database-migrations skill`

---

## Change Log

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0 | YYYY-MM-DD | [Author] | Initial architecture sketch from inception |
