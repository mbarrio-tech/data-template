---
name: debugging
description: Systematic approach to diagnosing and fixing bugs. Enforces reproduce-first, hypothesis-driven investigation, and prevents thrashing.
---

# Debugging

Use this skill when a test is failing, unexpected behaviour is observed, or a bug report is received. Apply this process in order — do not skip steps.

## The Iron Rule

**You must have a reproducible case before touching any code.**

A failing test, a repeatable sequence of steps, or a log trace showing the failure — one of these must exist before you write a single character of fix. Changing code without a reproduction is guessing, not debugging.

---

## Step 1: Reproduce

Before anything else:

- If a failing test exists: run it. Confirm it fails. Note the exact error message and stack trace.
- If no failing test exists: write one that demonstrates the symptom. Verify it fails for the right reason.
- If the bug is in a UI flow: document the exact steps to reproduce (environment, inputs, expected vs. actual).

**Do not proceed if you cannot reproduce the failure reliably.**

---

## Step 2: Read Before Writing

Before touching code:

1. **Read the failing test and the code under test.** Understand what the code is supposed to do.
2. **Check recent git history** (`git log --oneline -20` or `git log -p <file>`) — when was this code last changed?
3. **Read the logs.** Error messages, stack traces, and surrounding log lines contain the root cause more often than the code does.
4. **Read related tests.** Do passing tests constrain what the fix can be?

Resist the urge to immediately start changing things. Most debugging time is wasted on wrong hypotheses.

---

## Step 3: Form One Hypothesis

Based on what you read, form a single specific hypothesis:

> "I believe the failure is caused by [X] because [evidence Y shows Z]."

If you cannot complete that sentence with real evidence, keep reading. Do not form multiple hypotheses at once — test one, then move to the next if it is wrong.

---

## Step 4: Test the Hypothesis with the Minimal Change

Make the smallest possible change that would confirm or disprove the hypothesis. Examples:

- Add a log statement (not a fix yet — just observation)
- Isolate the failing code path into the smallest possible scope
- Change a single value or condition

**Verify the result.** If the hypothesis was wrong, revert the change completely before trying the next one.

---

## Step 5: Escalation Rule

If you have formed 3 hypotheses and none have led to the root cause:

**Stop and surface to the human.** Provide:
- The exact reproduction steps and failure message
- The 3 hypotheses tested and why each was wrong
- Your current best guess at where the root cause lies

Continuing past 3 failed hypotheses without help usually produces more churn, not faster resolution.

---

## Step 6: Apply the Confirmed Fix

Once you have confirmed the root cause:

1. Write the fix — minimal, targeted, changes only what is needed
2. Run the originally failing test — it must pass
3. Run the full test suite — confirm nothing else broke
4. If a regression test was missing (the bug existed without a test), add one now

---

## Step 7: Commit Discipline

One commit per confirmed fix:

```
fix(scope): brief description of what was broken and how it was fixed
```

Do not bundle multiple fixes in one commit. Do not clean up surrounding code in the same commit.

---

## What NOT to Do

- Do not change multiple things simultaneously and then run the test — you will not know what fixed it
- Do not assume the most recent change caused the bug — check the evidence
- Do not fix the symptom without confirming the root cause
- Do not write "defensive" code to work around a bug you don't understand — understand it first
- Do not mark a bug as fixed until the test passes AND the full suite passes
