---
name: verification-before-completion
description: Use before claiming any work is complete, fixed, or passing — requires running verification commands and confirming output before making any success claim. Evidence before assertions, always.
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is not efficiency — it is dishonesty.

**Core principle:** Evidence before claims, always.

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you have not run the verification command **in this message**, you cannot claim it passes.

## The Gate Function

Before claiming any status or expressing satisfaction:

1. **Identify** — what command proves this claim?
2. **Run** — execute the full command (fresh, complete — not from memory)
3. **Read** — full output, check exit code, count failures
4. **Verify** — does output confirm the claim?
   - If NO: state actual status with evidence
   - If YES: state claim WITH evidence attached
5. **Only then:** make the claim

Skipping any step = asserting without evidence.

## Common Failures

| Claim | Requires | Not Sufficient |
|---|---|---|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look OK |
| Bug fixed | Test for original symptom: passes | Code changed, assumed fixed |
| Requirements met | Line-by-line checklist | Tests passing |
| PR ready | All checks above completed | Agent reports success |

## Red Flags — Stop

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Done!", "All good!", "Fixed!")
- About to commit, push, or open a PR without running tests
- Trusting agent success reports without independent verification
- Relying on a partial check
- "Just this once"

## Rationalisation Prevention

| Excuse | Reality |
|---|---|
| "Should work now" | Run the verification |
| "I'm confident" | Confidence is not evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter does not equal compiler |
| "Agent said success" | Verify independently |
| "Partial check is enough" | Partial proves nothing |
| "Different wording so the rule does not apply" | Spirit over letter |

## Correct Pattern

```
✅ Run: npm test
   Output: 42/42 passing
   Claim: "All tests pass"

❌ Claim: "Tests should pass now"
   (no command run, no output shown)
```
