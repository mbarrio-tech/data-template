---
name: hotfix
description: Emergency response when a live feature causes a production incident or a critical bug is found post-merge. Covers rollback via feature flag and hotfix branch procedure.
---

# Hotfix — Emergency Response

Use this skill when a live feature is causing a production incident, a critical bug is found post-merge, or a deployed feature flag needs to be reverted immediately.

## Step 1: Triage — Rollback or Fix?

Ask these questions first:

| Question | Rollback | Hotfix |
|---|---|---|
| Is the affected feature behind a Live-ON flag? | Yes → rollback | No → hotfix |
| Is the fix a one-line config/data change? | — | Yes → hotfix |
| Is the root cause unknown? | Yes → rollback first, investigate after | No → hotfix |
| Can users work around it? | No → rollback | Yes → hotfix |

**Default: rollback first.** The flag system exists precisely for this. Investigate after the incident is contained, not during.

---

## Rollback Procedure (flag-flip)

**Use when:** the affected feature is behind a Live-ON flag and rolling it back stops the incident.

### Steps

1. **Identify the flag.** Read `docs/idf/feature-governance.md` → find the Live-ON flag for the affected feature.

2. **Flip the flag.** Change flag state from `Live-ON` to `Dead-OFF` in `docs/idf/feature-governance.md`.

3. **Deploy the flag change.** In your runtime (feature flag system, config, env variable) — set the flag to OFF. This must happen before the next user request hits the affected code path.

4. **Verify the incident is contained.** Confirm with the team or monitoring that the error rate has dropped.

5. **Update feature-governance.md.** Add a note to the flag row: date flipped, reason, incident reference.

6. **Write a drift-register entry.** In `docs/idf/drift-register.md`:
   - Type: `Rollback`
   - Intended: feature was Live-ON and serving users
   - Built/Actual: feature rolled back due to incident
   - Root cause: (if known at time of writing)
   - Process improvement: what would have caught this before going live?

7. **Notify the PO.** Brief summary: what was rolled back, why, and when the fix-and-relaunch plan will be ready.

8. **Do not relaunch the flag** until a hotfix cycle completes and guardian produces a PASS gate report.

---

## Hotfix Branch Procedure

**Use when:** the bug is not behind a flag, the fix is well-understood, and rollback is not an option.

### Steps

1. **Reproduce the bug.** Create a failing test that demonstrates the exact symptom. Do not proceed without a reproducible case.

2. **Branch from main** (not from the feature branch).
   ```bash
   git checkout main
   git pull
   git checkout -b hotfix/[short-description]
   ```

3. **Apply the minimal fix.** Change only what is needed to fix the confirmed root cause. Do not improve, refactor, or clean up surrounding code during a hotfix.

4. **Verify the fix.**
   - The failing test from Step 1 now passes
   - The full test suite passes (not just the affected test)

5. **Run expedited code review.** Invoke the `code-reviewer` agent with explicit P0 scope. Include:
   - The failing test before the fix
   - The minimal diff
   - The root cause statement

6. **Run expedited guardian review.** Invoke the `guardian` agent. Flag it as P0 in the session. Guardian still produces a 3-paragraph gate report — P0 does not skip the gate, it expedites it.

7. **Merge directly to main** after a single PASS review (not the normal PR cycle if that would take hours).
   ```bash
   git checkout main
   git merge hotfix/[short-description]
   git push
   git branch -d hotfix/[short-description]
   ```

8. **Tag the hotfix.**
   ```bash
   git tag hotfix/[short-description]-[date]
   git push --tags
   ```

9. **Write a drift-register entry.** Same as rollback procedure above.

10. **Post-incident:** write an intent statement for the next cycle that addresses the root cause (not just the symptom).

---

## After the Incident

Regardless of rollback or hotfix:

- [ ] Drift register entry written
- [ ] PO notified with brief
- [ ] Root cause documented (even if speculative — update when confirmed)
- [ ] Regression test added (if it was missing)
- [ ] Process improvement identified (what gate should have caught this?)
- [ ] Next cycle intent addresses the underlying cause

## What NOT to Do

- Do not skip the gate review because it is an emergency — expedite it, do not skip it
- Do not fix multiple issues in a single hotfix commit
- Do not merge a hotfix that does not have a regression test
- Do not relaunch a rolled-back flag without a new guardian PASS
