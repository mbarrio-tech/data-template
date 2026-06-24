---
name: brainstorming
description: "You MUST use this before any creative work — creating features, building components, adding functionality, or modifying behaviour. Explores user intent, requirements, and design before any implementation."
---

# Brainstorming Ideas Into Designs

Turn ideas into fully formed designs through collaborative dialogue before any code is written.

Start by understanding the current project context (read `docs/polaris/polaris.md` and `docs/architecture/architecture.md`), then ask questions one at a time to refine the idea. Once you understand what is being built, present the design and get user approval.

<HARD-GATE>
Do NOT write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY request regardless of perceived simplicity.
</HARD-GATE>

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every feature goes through this process. A config change, a single-function utility, a UI tweak — all of them. "Simple" tasks are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences), but you MUST present it and get approval before touching code.

## Checklist

Complete these in order — do not skip any step:

1. **Read project context** — check `docs/polaris/polaris.md`, `docs/architecture/architecture.md`, and recent git commits
2. **Assess scope** — if the request spans multiple independent subsystems, flag it for decomposition before proceeding
3. **Ask clarifying questions** — one at a time; understand purpose, constraints, and success criteria
4. **Propose 2–3 approaches** — with trade-offs and your recommendation
5. **Present design** — section by section, get approval after each section
6. **Write design doc** — save to `docs/designs/YYYY-MM-DD-<topic>-design.md` and commit
7. **Spec self-review** — scan for placeholders, contradictions, ambiguity, scope creep; fix inline
8. **User reviews spec** — ask user to read the committed spec file before proceeding
9. **Transition to planning** — invoke the `writing-plans` skill as the only next step

## Process

### Understanding the Idea

- Read polaris.md first — does this request serve an explicit deliverable?
- Before detailed questions, assess scope. If the request describes multiple independent subsystems, help the user decompose into sub-projects first. Each gets its own design → plan → implementation cycle.
- Ask one question per message
- Prefer multiple-choice questions when possible
- Focus on: purpose, constraints, success criteria, what "done" looks like

### Exploring Approaches

- Propose 2–3 approaches with clear trade-offs
- Lead with your recommended option and explain why
- Do not present a single option as if there were no alternatives

### Presenting the Design

- Scale each section to its complexity: a few sentences if simple, up to 200–300 words if nuanced
- Ask after each section whether it looks right before continuing
- Cover: architecture, components, data flow, error handling, testing approach
- Design for isolation: each component should have one clear purpose, communicate through well-defined interfaces, and be independently testable

### Working in Existing Codebases

- Explore the current structure before proposing changes — follow existing patterns
- Where existing code causes problems for the work (grown too large, tangled responsibilities), include targeted improvements as part of the design
- Do not propose unrelated refactoring

## After the Design

- Save the validated design to `docs/designs/YYYY-MM-DD-<topic>-design.md`
- Commit the design doc: `docs: add design for <topic>`
- Run self-review checklist:
  1. **Placeholder scan** — any TBD, TODO, incomplete sections? Fix them.
  2. **Internal consistency** — do any sections contradict each other?
  3. **Scope check** — does everything in the design map to a deliverable in polaris.md?
  4. **Ambiguity check** — could any sentence be interpreted two different ways? Resolve it.
- Ask the user to review the committed spec file
- **Only then:** invoke the `writing-plans` skill

## Common Mistakes

- Skipping design because "it's obvious" — it never is
- Asking multiple questions in one message — always one at a time
- Writing code during the discussion phase — even pseudocode counts
- Saving the design doc after receiving approval but before self-review
