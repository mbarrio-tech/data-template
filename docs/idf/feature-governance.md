---
version: 1.0
status: active
last-updated: YYYY-MM-DD
owner: "[Product Owner — toggle decision · Builder — creates flag · Tech Lead — dead flag cleanup]"
idf-ref: "Section 07 — Artifacts, Section 03 — Roles (Builder), Section 04 — Delivery Cycle"
---

# Feature Governance Registry

> Every feature flag and its current lifecycle state.
>
> **IDF R3:** Every change ships behind a flag. No exception.
> Deployment and release are separate events.
>
> Flag lifecycle:
> - `Pending-OFF` — deployed to production, not yet exposed to users
> - `Live-ON` — active, released, part of the live context — monitored
> - `Dead-OFF` — permanently abandoned or superseded — **must be removed at next Context Reset**
>
> Dead-OFF flags left in the codebase expand the active context surface and increase drift probability.

<!-- IDF NOTE: Maps to FEATURE_GOVERNANCE_REGISTRY in IDF v7.11 Section 07. -->

---

## Active Flags

| Flag Name | State | Cycle | PO Owner | Deployed | Activated | Notes |
|---|---|---|---|---|---|---|
| *(no flags yet)* | — | — | — | — | — | — |

---

## Dead Flags — Pending Cleanup

> These flags are Dead-OFF and must be removed from the codebase at the next Context Reset.
> After code removal, move the row to the Retired section below.

| Flag Name | Cycle Created | Cycle Killed | Reason | Code Removed? |
|---|---|---|---|---|
| *(none)* | — | — | — | — |

---

## Retired Flags

> Flags that have been fully removed from the codebase. Kept here as a record.

| Flag Name | Cycle | Outcome | Removed Date |
|---|---|---|---|
| *(none yet)* | — | — | — |

---

## Flag Naming Convention

Flags must be:
- **Snake_case** and **lowercase**
- **Descriptive of the feature**, not the ticket: `checkout_simplified_payment` not `feat_1042`
- **Prefixed by domain** if the project has multiple domains: `payments_simplified_flow`, `auth_magic_link`

## PO Toggle Procedure

1. Confirm Craft Engineer + Quality Advocate have signed off on the gate report
2. Update this registry: change `Pending-OFF` → `Live-ON` and add `activated` date
3. Flip the flag in the flag service / config
4. Update SYSTEM_MEMORY.md Feature Governance Registry table (same data, different audience)
5. Monitor error rates and client signals for 24 hours minimum

---

## Emergency Rollback Procedure

**Use when:** a Live-ON flag is causing a production incident and the fix is not yet ready.

> Do not attempt a code fix while the incident is live. Rollback first, investigate after.

1. **Identify the flag.** Confirm which Live-ON flag is associated with the incident (row in Active Flags table above).
2. **Flip the flag OFF.** In the runtime flag system / config, set the flag value to OFF immediately.
3. **Update this registry.** Change flag state to `Dead-OFF` and add a note: `Rolled back YYYY-MM-DD — incident: [brief description]`.
4. **Confirm containment.** Verify with the team or monitoring that the incident is resolved.
5. **Write a drift-register entry.** Document the incident in `docs/idf/drift-register.md`.
6. **Notify the PO.** Provide a brief: what was rolled back, why, expected relaunch timeline.
7. **Do not relaunch the flag** until root cause is identified, a fix ships, and guardian produces a PASS gate report.

For detailed guidance including hotfix branch procedure, invoke: `Run the incident-responder agent` or `Use the hotfix skill`.
