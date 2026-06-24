---
name: context-reset
description: Use every 5–10 cycles (or when gate first-pass rate is declining without change in intent clarity) to prune System Memory and the Capability Library. Prevents context debt from corrupting agent output.
---

# Context Reset

## What This Is

A Context Reset is a scheduled audit of the system's persistent memory. It is not a refactor, not a planning session, and not a retrospective. It is a pruning exercise.

> **Context debt accumulates proportionally to cycle volume.**
> A team running 3 cycles per day accumulates context debt ~15× faster than a team running 1 cycle per week.
> High-throughput teams must run Context Reset every 5 cycles, not every 10.

**Signal that reset is overdue:** Declining gate first-pass rate with no change in intent clarity.

---

## When to Trigger

| Trigger | Condition |
|---|---|
| Cycle count | Every 5–10 cycles (high throughput → every 5) |
| Drift signal | Gate first-pass rate drops below 60% for 2+ consecutive cycles |
| PO concern | PO notices agents producing confident but wrong output |
| Dead-OFF flags | Feature Governance Registry has Dead-OFF flags pending cleanup |

---

## Phase 1: SYSTEM_MEMORY.md Audit

**Participants:** Orchestrator + Tech Lead
**For every entry in SYSTEM_MEMORY.md**, answer these questions:

### Architectural Decisions in Force — per entry
- [ ] **Is this still true?** Does the current codebase reflect this decision?
- [ ] **Is this still relevant?** Would an agent need this for a cycle today?
- [ ] **Does this contradict another entry?** Contradictions must be resolved, not coexist.

**If any answer is NO → remove the entry.** Use `git log SYSTEM_MEMORY.md` to recover it if needed.

### Feature Governance Registry — per flag
- [ ] **Is this flag Live-ON and stable?** If yes and it has been live for 3+ cycles → mark for Dead-OFF and code removal.
- [ ] **Is this flag Dead-OFF?** → Remove the code, then remove the entry.
- [ ] **Is this flag Pending-OFF for 2+ cycles with no gate review?** → Escalate to PO immediately.

### Cycle Log — per entry
- [ ] No action needed on the log itself — it is append-only.
- [ ] But if the log references a decision that is no longer in "Architectural Decisions in Force", confirm the decision was intentionally removed.

### Provisional Entries — all entries marked (provisional)
- [ ] Tech Lead reviews each one: confirm, update, or remove.
- [ ] All provisional entries must be resolved before the reset is complete.

---

## Phase 1b: Drift Analysis (optional but recommended)

Before pruning, run the `drift-analyst` agent if:
- Gate first-pass rate has been below 60% for 2+ cycles
- There are 3+ unresolved drift-register entries with no process improvement noted
- Orchestrator has flagged recurring ambiguity in the same domain for 2+ cycles

The drift analyst will read intent-log, gate-reports, and the drift register to surface cross-cycle patterns before the capability library is pruned. This ensures the pruning step has context on which capabilities are underperforming vs. which are simply not being applied.

Invoke: `Run the drift-analyst agent`

---

## Phase 2: Capability Library Audit

**Participants:** Craft Engineer
**For every file in `docs/capability-library/`**, answer:

- [ ] **Has this capability been used in the last N cycles?** Check the cycle log. Unused capabilities are candidates for removal.
- [ ] **Does this capability reflect current patterns?** Compare against recent Builder output and gate reports.
- [ ] **Are there recurring Craft Review corrections not yet encoded here?** Harvest them before closing the reset.
- [ ] **Does this capability contradict current architecture decisions?** If yes, update the capability or the decision — not both.

---

## Phase 3: Dead Flag Code Removal

**Participants:** Craft Engineer
For each Dead-OFF flag in `docs/idf/feature-governance.md`:

1. Find all flag references in the codebase: `grep -r "flag_name" src/`
2. Remove the flag check and the dead code path
3. Run tests — confirm nothing breaks
4. Commit: `chore(flags): remove dead flag [flag_name] (cycle N)`
5. Update `docs/idf/feature-governance.md` — move flag to **Retired** section
6. Remove the flag's entry from `docs/SYSTEM_MEMORY.md` Feature Governance Registry

---

## Phase 4: Reset Record

After completing all three phases, add an entry to `docs/SYSTEM_MEMORY.md`:

```markdown
# In Project Identity table:
Last Context Reset: YYYY-MM-DD

# In Cycle Log table:
| Context Reset | YYYY-MM-DD | System memory pruned, N entries removed | — | — | Complete |
```

And add a CHANGELOG.md entry:
```
## Context Reset — Cycle [N] · YYYY-MM-DD
- Removed N stale SYSTEM_MEMORY entries
- Updated N capability files
- Cleaned N Dead-OFF flags from codebase
```

---

## What Good Looks Like After Reset

- SYSTEM_MEMORY.md has no provisional entries
- No Dead-OFF flags remain in the registry or codebase
- Every capability file in the library has been used in the last N cycles
- No contradicting entries remain in SYSTEM_MEMORY
- Gate first-pass rate stabilises or improves in the next 2–3 cycles
