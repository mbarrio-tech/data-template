---
name: writing-plans
description: Use when you have an approved design spec for a multi-step task and need to create a detailed implementation plan before touching code.
---

# Writing Plans

## Overview

Create a comprehensive implementation plan from an approved design spec. The plan must be detailed enough that any engineer — with zero context on the codebase — can execute each task in 2–5 minutes in sequence.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Prerequisite:** An approved design doc must exist in `docs/designs/`. If it does not, stop and invoke the `brainstorming` skill first.

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Scope Check

Before writing tasks, check: does the design cover multiple independent subsystems? If so, split into separate plans — one per subsystem. Each plan must produce working, testable software on its own.

## File Structure First

Before defining tasks, map out which files will be created or modified, and what each one is responsible for:

- Each file has one clear responsibility
- Files that change together live together
- Prefer smaller focused files over large files that do too much
- In existing codebases, follow established patterns

## Task Granularity

Every step is **2–5 minutes** of work — one action at a time:

```
- Write the failing test       (step)
- Run it to verify it fails    (step)
- Write the minimal implementation (step)
- Run tests to verify they pass (step)
- Commit                       (step)
```

## Plan Document Format

Every plan starts with this header:

```markdown
# [Feature Name] Implementation Plan

> **For AI workers:** Use the `subagent-driven-development` skill to execute this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]
**Design doc:** [Link to the design doc in docs/designs/]
**Architecture:** [2–3 sentences about the approach]
**Tech stack:** [Key technologies]
**Polaris deliverable:** [Which deliverable from polaris.md this serves]

---
```

## Task Format

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.ts`
- Modify: `exact/path/to/existing.ts`
- Test: `tests/exact/path/to/test.ts`

- [ ] **Step 1: Write the failing test**
```typescript
test('specific behaviour', () => {
  const result = fn(input)
  expect(result).toEqual(expected)
})
```

- [ ] **Step 2: Run test — verify it fails**
Run: `npm test tests/path/test.ts`
Expected: FAIL with "[reason]"

- [ ] **Step 3: Write minimal implementation**
```typescript
export function fn(input: Input): Output {
  return expected
}
```

- [ ] **Step 4: Run tests — verify they pass**
Run: `npm test`
Expected: All pass

- [ ] **Step 5: Commit**
```bash
git commit -m "feat(scope): description"
```
````

## No Placeholders Rule

The following are plan failures — fix before saving:

| Placeholder | Fix |
|---|---|
| "TBD", "TODO", "implement later" | Write the actual content |
| "Add appropriate error handling" | Write the exact error handling code |
| "Similar to Task N" | Repeat the actual code |
| "Write tests for the above" | Write the actual test code |
| Steps that describe without showing code | Show the code |

## Self-Review Checklist

Before saving the plan:

1. **Spec coverage** — every requirement in the design doc has at least one task
2. **Placeholder scan** — no TBD, vague steps, or "similar to" references
3. **Type consistency** — function signatures match across tasks that call each other
4. **Test-first** — every task writes the failing test before any implementation step
5. **Polaris traceability** — the plan header links to a real deliverable in polaris.md

## Common Mistakes

- Writing implementation steps before the test step
- Using "Add error handling" without showing the actual try/catch
- One giant task instead of 2–5 minute steps
- Starting to plan without an approved design doc
