# Capability Library

> Domain-specific instruction sets that encode **how this team builds things**.
>
> Each capability file is a short markdown document that tells Builder agents exactly how to implement a specific type of task in this codebase — auth patterns, API conventions, component structure, deploy procedures.
>
> The Capability Library is what prevents Builders from re-learning the same conventions on every cycle.
> It grows through **Capability Harvest** signal events and is governed by the Tech Lead.

<!-- IDF NOTE: Maps to CAPABILITY_LIBRARY in IDF v7.11 Section 07. -->

---

## How to Use This Library

**Builders (agents):** Before starting a task, check whether a capability file exists for the domain your task touches. If yes, read it fully before writing a single line of code. The capability file is your contract.

**Orchestrator:** When decomposing a cycle intent, tag each task with its relevant capability file (e.g. `Capability: api-contracts`). If no capability file exists for a domain, flag it to the Craft Engineer before starting.

**Craft Engineer:** You own this library. Create new capability files through Capability Harvest. Update existing ones when you notice a recurring Craft Review correction. Audit all files at every Context Reset.

---

## Capability File Template

Create a new file `docs/capability-library/[domain].md` using this structure:

```markdown
---
version: 1.0
last-updated: YYYY-MM-DD
owner: "[Craft Engineer name]"
domain: "[e.g. api-contracts]"
applies-to: "[e.g. All REST API endpoints in src/api/]"
---

# Capability: [Domain Name]

## Summary
One sentence: what this capability covers and when to use it.

## Pattern

[The exact pattern — code examples, file paths, naming conventions.
Be specific enough that a Builder agent with no project context
could follow this without asking a single question.]

## Example

[A real example from this codebase. Reference actual file paths.]

## Anti-Patterns

[What NOT to do — and why. Include examples of the wrong way.]

## When to Create a New Variant

[Under what conditions is a different approach acceptable? Be explicit.]
```

---

## Current Capabilities

*(No capability files yet — the first ones will be harvested after the first few cycles of real work.)*

| Domain | File | Created | Last Updated |
|---|---|---|---|
| *(none yet)* | — | — | — |

---

## Harvest Trigger

A new capability file is created when:
1. The Guardian or Orchestrator detects the same pattern being explained in more than one cycle
2. A Craft Review correction is made for the **second time** on the same class of problem
3. The Orchestrator cannot decompose a task because no convention exists for this domain

Use `skills/capability-harvest` to run the full harvest workflow.
