---
name: capability-harvest
description: Use when the Guardian or Orchestrator detects a repeated pattern — the same convention has been explained, corrected, or reinvented in 2+ cycles. Encodes the pattern into docs/capability-library/ so Builders never need to re-learn it.
---

# Capability Harvest

## What This Is

A Capability Harvest encodes a discovered pattern into a permanent capability file so the team never has to teach it again.

> **IDF principle:** When the Craft Engineer notices "the Builder keeps solving this wrong", the correct response is to encode the fix into a capability file — not to fix it manually each time.

---

## Harvest Triggers

| Trigger | Source | Threshold |
|---|---|---|
| Recurring Craft Review correction | Gate reports | Same class of correction made 2+ times |
| Repeated Orchestrator convention note | Task lists | Same convention explained in 2+ cycles |
| Guardian auto-test noise | Gate reports | Same warning or pattern found 3+ times |
| Onboarding friction | New team member | They asked the same question that a capability file would answer |
| Tech Lead architectural decision | Architecture decisions | New constraint that every Builder must follow going forward |

---

## Phase 1: Pattern Identification

**Participants:** Craft Engineer (lead) + Orchestrator (provides cycle evidence)

1. Collect evidence: which cycles showed this pattern? Pull from:
   - `docs/idf/gate-reports/` — Craft Review corrections
   - `docs/SYSTEM_MEMORY.md` Known Patterns section — provisional entries
   - `docs/idf/drift-register.md` — drift entries with `Root cause: Missing capability file`

2. Define the pattern precisely:
   - What domain does it cover? (e.g. `api-contracts`, `auth`, `frontend-components`)
   - What is the exact convention the Builder should follow?
   - What is the anti-pattern that keeps appearing?
   - Are there real examples in the codebase right now?

3. Confirm the pattern is:
   - [ ] Reusable across multiple cycles (not a one-off)
   - [ ] Specific to this codebase (not a generic best practice better served by docs)
   - [ ] Stable enough to encode (not currently under active architectural discussion)

---

## Phase 2: Write the Capability File

Create `docs/capability-library/[domain].md` using the template from `docs/capability-library/README.md`.

Requirements for the file:
- **Pattern section must have code examples** — abstract descriptions without code produce the same drift the capability is meant to prevent
- **Anti-pattern section is mandatory** — include the wrong way with a comment explaining why
- **Real file path references** — point to actual files in `src/`, not hypothetical ones
- **Short** — if a Builder needs more than 5 minutes to read and apply this, it is too long

---

## Phase 3: Validate Against Recent Output

Before committing the capability file:

1. Pick the last 2 Builder outputs that showed the problem pattern
2. Ask: "If the Builder had read this capability file first, would the output have been correct?"
3. If YES → the capability file is ready
4. If NO → the file is still too abstract. Add more specifics.

---

## Phase 4: Register and Activate

1. Add the new capability to the **Current Capabilities** table in `docs/capability-library/README.md`
2. Update `docs/SYSTEM_MEMORY.md` Known Patterns table:
   - Change status from `Provisional` to `Capability file: [domain].md`
3. Commit: `docs(capability-library): add [domain] capability (harvested from cycle N)`
4. Notify the Orchestrator: "New capability file available for `[domain]` — tag tasks accordingly"

---

## The Craft Engineer's Discipline

The harvest workflow is complete when the **next set of Builder output** no longer shows the problem. If the pattern reappears after the capability file is created:

1. The capability file is too abstract — add more specifics
2. The Orchestrator is not tagging tasks with the correct capability file — fix the task template
3. The pattern is deeper than conventions — it may be an architectural problem requiring a different solution
