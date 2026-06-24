---
version: 1.0
status: active
last-updated: YYYY-MM-DD
owner: "[Product Owner]"
idf-ref: "Section 07 — Artifacts"
---

# Drift Register

> A log of detected divergences between what was intended and what was actually implemented, with the correction taken.
>
> **This is the most valuable long-term document in the project.**
> It maps where the system's judgment differs from the PO's and teaches better intent writing over time.
> It also tells the team where the client's stated intent was unclear or changed mid-cycle.
>
> Every drift entry is a learning. Review this doc before writing intent for the next cycle.

<!-- IDF NOTE: Maps to DRIFT_REGISTER.md in IDF v7.11 Section 07. -->

---

## How to Add an Entry

Drift is detected at:
- **Gate review** — what the Guardian reports doesn't match the intent statement
- **Drift Check signal event** — every 10–20 cycles, PO + Orchestrator compare intent-log to what shipped
- **Post-release** — live signals reveal that the shipped feature didn't actually solve the client problem

```markdown
## DR-NNN — [Short Drift Title]

**Cycle:** N
**Date Detected:** YYYY-MM-DD
**Detected by:** PO / Guardian / Craft Engineer / Client signal
**Type:** Intent Ambiguity / Scope Creep / Technical Deviation / Requirements Change

**What was intended:**
[The original intent statement or acceptance criterion]

**What was built:**
[What the Builder actually shipped]

**Root cause:**
[Why did this happen? Ambiguous intent? Missing capability file? Incorrect decomposition?]

**Correction taken:**
[What change was made — to the code, the intent, the capability library, or the process]

**Next cycle impact:**
[Does this change the next cycle's intent? If yes, how?]

**Process improvement:**
[What will be done differently to prevent this class of drift? Update skill? Update capability file? Better intent example?]
```

---

## Register

*(No drift entries yet — the first one will come from the first real cycle)*
