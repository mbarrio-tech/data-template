# Gate Reports

> This folder contains Guardian gate reports — one per delivery cycle.
>
> **Format:** `GATE_REPORT_cycle-N.md` (e.g. `GATE_REPORT_cycle-14.md`)
>
> **Lifecycle:** A gate report is created by the Guardian agent when auto-tests pass. It expires (is archived here) when the PO makes a gate decision. It is never deleted — it is the audit trail of every shipping decision.

<!-- IDF NOTE: Maps to GATE_REPORT_{cycle}.md in IDF v7.11 Section 07. -->

---

## Gate Report Format

Every gate report is **exactly three paragraphs**. No more. This constraint exists to keep PO review time under 30 minutes (IDF target: <30 min from report to decision).

```markdown
# Gate Report — Cycle N

**Date:** YYYY-MM-DD HH:MM UTC
**Flag:** [flag_name]
**Decision:** PASS / FLAG / FAIL

---

**What was built:** [One paragraph — the feature, the change, what it does for the client.
Reference the original intent statement. Be specific about what was implemented,
not how it was implemented.]

**Signals:** [One paragraph — test results (N passing, N failing), security scan status,
bundle size delta, performance score, cost delta estimate, client signal reference
if applicable. Numbers only — no qualitative claims without data.]

**Decision:** [One paragraph — PASS / FLAG / FAIL with clear reasoning.
If PASS: recommend flag activation and propose next cycle from the client signal log.
If FLAG: list exactly what needs human review before flag activation.
If FAIL: list what must be fixed, route back to Builder via Orchestrator.]
```

---

## Decision Reference

| Decision | Meaning | Action |
|---|---|---|
| `PASS` | All checks clear, Guardian recommends Live-ON | PO reads report, approves, flips flag |
| `FLAG` | Checks pass but human review needed on a specific point | Craft Engineer or QA Advocate reviews flagged item, then PO decides |
| `FAIL` | Auto-test failure or critical issue found | Orchestrator re-plans, Builder fixes, Guardian re-runs — PO not involved |

---

## Reports

*(Gate reports are added here by the Guardian agent. The first real report appears after Cycle 1.)*
