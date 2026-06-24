---
name: writing-intent
description: Use when reviewing or validating an intent document before ingestion. Enforces IDF R1 — express client outcomes, not task lists. Also used by the requirements-analyst agent during ingestion to validate extracted intent. The PO writes in their own tool and delivers the document externally — this skill governs the quality standard the document must meet.
---

# Writing Intent

## How Intent Enters the System

The PO writes intent in whatever tool they use — email, Word, Confluence, meeting notes. They deliver it externally to the dev team. A dev runs the `requirements-analyst` agent, pastes or attaches the document, and the agent ingests it into `docs/idf/intent-log.md`. **The PO never edits repo files.**

This skill defines the quality standard the document must meet for ingestion to succeed. If the extracted intent fails this standard, the requirements-analyst agent returns a specific rewrite request to the PO before writing anything.

---

## The Rule (IDF R1)

> **Express outcomes, not instructions.**
> The right input to the system is a clear statement of desired client outcome.
> Task lists, acceptance criteria, and implementation instructions are *outputs* of decomposition — not inputs to it.
> State what needs to be true for the client. Let the system determine how.

---

## The Test for Good Intent

A good intent statement answers: **"What will be true for the client when this is done?"**

Ask yourself:
1. Does this describe a client outcome — something the client experiences or benefits from?
2. Is there a measurable signal that confirms success?
3. Could this be achieved in more than one way? (If only one way, it's a task, not intent)
4. Does this avoid prescribing implementation?

If the answer to any of 1–3 is no, rewrite before passing to the Orchestrator.

---

## Good vs Bad Intent

| Bad Intent (task list) | Good Intent (client outcome) |
|---|---|
| "Add a login button to the homepage" | "Users can log in and reach their dashboard without friction" |
| "Refactor the payment form to use a single field" | "Reduce checkout abandonment at the payment step" |
| "Fix the null pointer exception in UserService" | "Users no longer see error screens when accessing their profile" |
| "Integrate with the new CRM API" | "Sales team can see customer interaction history without switching tools" |
| "Update the dashboard to show weekly totals" | "Managers can understand weekly team output without opening a spreadsheet" |

---

## Required Elements of a Cycle Intent Statement

```markdown
## Cycle [N] — Intent

Date: YYYY-MM-DD
Owner: [Product Owner name]

Intent: [One to three sentences. Client outcome framed. No task list.]

Client signal ref: [CS-NNN — the signal this intent addresses, if applicable]
Success signal: [What metric or observable behaviour confirms success?]
```

### Minimum viable intent
- One clear sentence describing the client outcome
- A success signal that can be observed after deploy

### When to add more
- If the scope boundary is not obvious (what is and is not included)
- If there is a client signal reference that explains the "why"
- If this is a correction to a previous cycle's intent (note the drift reference)

---

## Ambiguity Stops Execution

If the Orchestrator escalates back with a clarifying question, the correct response is:
1. Answer the specific question
2. Revise the intent statement if needed
3. Resubmit

**Do not say "use your judgment"** — that is the most common source of drift.
**Do not add task details** — that crosses into decomposition, which is the Orchestrator's job.

---

## Intent Injection Checklist

Before submitting intent to the Orchestrator:

- [ ] Describes what will be true for the client — not what will be built
- [ ] Avoids naming specific UI elements, functions, or implementation details
- [ ] Has a measurable success signal
- [ ] References a client signal (CS-NNN) where applicable
- [ ] Does not contain a task list disguised as an outcome
- [ ] Is scoped — the boundary of this cycle is clear
