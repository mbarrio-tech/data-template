---
version: 1.0
status: active
last-updated: YYYY-MM-DD
owner: "[Orchestrator writes · Product Owner uses]"
idf-ref: "Section 07 — Artifacts"
---

# Intent Log

> Chronological record of every cycle intent statement and what was actually shipped.
> **Backward-facing only — this is not a backlog.**
> Used during Drift Checks to identify divergence between what was asked for and what was built.
>
> Written by the Orchestrator at cycle close. The PO reviews during every Drift Check.

<!-- IDF NOTE: Maps to INTENT_LOG.md in IDF v7.11 Section 07. -->

---

## How to Add an Entry

The Orchestrator adds a row at cycle close. The PO confirms the "Outcome" column after the flag has been Live-ON for at least 24 hours.

---

## Log

| Cycle | Date | PO Owner | Intent Statement | What Shipped | Flag | Client Signal Ref | Outcome |
|---|---|---|---|---|---|---|---|
| 0 | YYYY-MM-DD | — | Project bootstrapped | Template files populated | — | — | Complete |

---

## Cycle Intent Detail

> For complex cycles, expand the intent here. Simple cycles (one clear outcome) do not need a detail block.

### Cycle 0 — Inception

**Intent:** Bootstrap the project repository with team and client context so every AI tool session starts informed.

**Delivered:** CLAUDE.md, docs/polaris/polaris.md, docs/architecture/architecture.md, SYSTEM_MEMORY.md, and all IDF artifact files populated from the Intent Document.

**Drift:** None — this was a setup cycle.
