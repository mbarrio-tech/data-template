---
name: subagent-driven-development
description: Use when executing an implementation plan with independent tasks in the current Claude Code session.
---

# Subagent-Driven Development

Execute a plan by dispatching a fresh subagent per task, with two-stage review after each: spec compliance first, then code quality.

**Why subagents:** Fresh subagents have isolated context. You craft exactly what they need — they do not inherit your session history or assumptions. This keeps implementation focused and preserves your coordination context.

**Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration.

## When to Use

- You have an implementation plan in `docs/plans/`
- Tasks in the plan are mostly independent (completing task N does not require reading task N-1's code)
- You are working in the current Claude Code session (not a parallel worktree)

If tasks are tightly coupled or you need parallel worktrees, coordinate manually instead.

## The Process

### Before Starting

1. Read the full plan from `docs/plans/`
2. Extract all tasks with their full text
3. Note shared context (repo structure, tech stack, test commands)
4. Create a todo list with all tasks

### Per Task Loop

For each task:

**1. Dispatch implementer subagent**

Give the subagent:
- The full text of the task (exact steps, file paths, code from plan)
- Shared context: project tech stack, test command, coding conventions
- A mandate: follow the plan exactly, write the failing test first, commit after tests pass

**2. If subagent asks questions**

Answer with specifics. If the same question comes up twice, the plan is ambiguous — update the plan before continuing.

**3. After implementer completes**

Dispatch a **spec reviewer subagent** with:
- The task text from the plan
- The git diff of what was implemented (`git diff HEAD~1`)
- Mandate: check that every step in the plan task is reflected in the diff

If gaps found: send implementer subagent back to fix. Re-review after fix.

**4. After spec review passes**

Dispatch a **code quality reviewer subagent** with:
- The git diff
- The project's `docs/architecture/architecture.md` and `docs/security/security.md`
- Mandate: check code quality, security controls, naming, error handling

If issues found: send implementer subagent back to fix. Re-review after fix.

**5. Mark task complete** in todo list, move to next task.

### After All Tasks

Dispatch a final **code-reviewer agent** review of the entire implementation (all commits together), then invoke the `finishing-a-development-branch` skill.

## What Subagents Should Never Do

- Read your session history or assume context not explicitly given
- Skip the failing test step
- Commit without tests passing
- Implement more than the current task specifies

## Common Mistakes

- Giving subagents your full session context — craft only what they need
- Skipping spec review to save time — this is where plan drift is caught
- Running both review stages as one subagent — keep them separate and focused
- Continuing when a subagent reports success without verifying the git diff
