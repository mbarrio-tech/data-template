---
version: 1.0
status: active
last-updated: YYYY-MM-DD
owner: "[Dependency Broker agent · Tech Lead review]"
idf-ref: "Section 07 — Artifacts, Section 03 — Roles (Dependency Broker)"
---

# Dependencies

> Cross-team contracts, shared components, and API agreements.
> Teams pull from this file before planning a cycle to identify potential blockers early.
> The Dependency Broker writes to it whenever a new dependency is detected.

<!-- IDF NOTE: Maps to DEPENDENCIES.md in IDF v7.11 Section 07. -->

---

## How to Read This File Before Planning a Cycle

Before the Orchestrator decomposes a new cycle intent, check:
1. Does any task touch an API, component, or service owned by another team? → Check **External Dependencies** below
2. Is any upstream team currently blocked or in maintenance? → Check **Blocker Log** below
3. Are there any breaking changes announced in the last sprint? → Check **Upcoming Changes** below

---

## External Dependencies

| Dependency | Owner Team | Type | Contract / Version | Status | Last Reviewed |
|---|---|---|---|---|---|
| *(none registered yet)* | — | — | — | Active | — |

**Types:** `API` · `SDK` · `Shared Component` · `Service` · `Auth Provider` · `Data Feed`
**Status:** `Active` · `Deprecated — migration planned` · `Blocked` · `Under Change`

---

## Internal Shared Modules

> Components or packages this project exposes to other teams, or consumes from within the same org.

| Module | Direction | Consumer / Provider | Contract | Version |
|---|---|---|---|---|
| *(none yet)* | — | — | — | — |

---

## Blocker Log

> Active blockers that are preventing or delaying a cycle. The Dependency Broker escalates to stakeholder level if a blocker persists beyond one cycle.

| Blocker ID | Raised | Blocking Cycle | Description | Owner | Resolution ETA | Status |
|---|---|---|---|---|---|---|
| *(none)* | — | — | — | — | — | — |

---

## Upcoming Breaking Changes

> Announced changes from other teams that may affect this project in upcoming cycles.

| Change | From Team | Affects | Effective Date | Action Required |
|---|---|---|---|---|
| *(none announced)* | — | — | — | — |

---

## Cross-Team Communication Protocol

Per IDF Section 08:
- All cross-team communication is mediated by the Dependency Broker agent
- No direct team-to-team coordination channels
- When the Orchestrator detects a cross-team need during decomposition: log it here immediately and notify affected POs before proceeding
- Resolution target: within the same cycle
- Escalation path: Dependency Broker → affected POs → Tech Leads → Stakeholders
