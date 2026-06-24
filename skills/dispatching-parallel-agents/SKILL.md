---
name: dispatching-parallel-agents
description: Use when facing 2 or more independent problems or tasks that do not share state and can be investigated or implemented simultaneously.
---

# Dispatching Parallel Agents

## Overview

When multiple independent problems exist — different failing test files, different subsystems, different bugs — investigating them sequentially wastes time. Each investigation is independent and can run in parallel.

**Core principle:** One agent per independent problem domain. Craft their context precisely — they get exactly what they need, never your session history.

## When to Use

**Use when:**
- 2+ test files or subsystems failing with different root causes
- Multiple independent features can be implemented in parallel
- Each problem can be fully understood without context from the others
- No shared mutable state between the problems

**Do not use when:**
- Failures are related (fixing one may fix others)
- Agents would write to the same files simultaneously
- Full system state must be understood before any individual problem makes sense

## The Pattern

### 1. Identify Independent Domains

Group problems by what is broken or what needs building:

```
Problem A: Authentication service — JWT validation failing
Problem B: Upload service — file size limit not enforced
Problem C: Notification service — emails not sending in staging
```

Each domain is independent. Fixing JWT does not affect uploads or notifications.

### 2. Craft Focused Agent Tasks

Each agent gets:
- **Exact scope** — the one problem they are solving (no more)
- **Relevant context** — only the files, docs, and commands they need
- **Success criteria** — how they know they are done
- **Constraints** — what they must not touch

Do not give agents each other's context. Do not tell them other agents are running.

### 3. Dispatch Simultaneously

Launch all agents at the same time. You coordinate; they execute.

### 4. Collect and Integrate Results

When all agents report completion:
- Review each diff independently
- Check for any unexpected overlaps (rare but possible)
- Merge results in order if needed
- Run the full test suite across all changes together

## Example Agent Brief

```
You are investigating a failing test in the authentication service.

Context:
- Repo: project-template
- Tech stack: Node.js 20, Express, Jest
- Failing test: tests/auth/jwt-validation.test.ts
- Test command: npm test tests/auth/jwt-validation.test.ts

Your task:
1. Read the failing test and understand what it expects
2. Trace the failure to its root cause
3. Implement the minimal fix
4. Verify the test passes
5. Verify no other tests regress (run npm test)
6. Commit: fix(auth): [description]

Do NOT touch anything outside the auth/ directory.
Report back: root cause, what you changed, test output.
```

## Common Mistakes

- Sending agents your full conversation history — they only need precise, relevant context
- Dispatching agents on related problems — they may produce conflicting fixes
- Not running the full test suite after integrating all agent results
- Trusting agent success reports — always verify the git diff
