# Agents

This folder contains AI agent definitions for the project.
Each agent is a markdown file with a YAML frontmatter header that defines its name, description, and behaviour.

## How to Invoke

**In Claude Code** — agents are automatically available. Reference by name:
> "Run the inception agent" or "Run the onboarding guide for [Name]"

---

## Available Agents

### `inception` — Project Bootstrap

**File:** [inception.md](inception.md)

Run **once** after cloning this template. Asks you key questions about the project, accepts the validated Intent Document from product, and populates all template placeholders across:
- `CLAUDE.md`
- `docs/polaris/polaris.md`
- `docs/architecture/architecture.md`

Ends with a guided first commit: `chore: project inception — [project name]`

**When to invoke:** Immediately after cloning, before any other work.

---

### `onboarding-guide` — New Team Member Guide

**File:** [onboarding-guide.md](onboarding-guide.md)

Guides a new team member through the project. Covers:
- What the project is (polaris.md walkthrough)
- How it is built (architecture.md walkthrough)
- Security rules every developer must know
- Local dev setup
- First task workflow and working agreements

**When to invoke:** Whenever a new developer, analyst, or contributor joins the project.

---

### `code-reviewer` — Code Review

**File:** [code-reviewer.md](code-reviewer.md)

Reviews a completed feature branch for:
- Alignment with polaris.md deliverables and acceptance criteria
- Architectural consistency (architecture.md)
- Security controls (security.md + OWASP)
- Test coverage against targets (test.md)
- Code quality and conventions

Produces a structured report: Critical / Important / Suggestions.

**When to invoke:** After completing a feature, before raising a pull request.

---

### `orchestrator` — Intent Decomposition and Cycle Memory

**File:** [orchestrator.md](orchestrator.md)

The IDF Orchestrator. Decomposes a PO intent statement into a sequenced task list for Builder agents. Reads SYSTEM_MEMORY.md, polaris.md, and the capability-library before producing any tasks. Escalates to the PO if intent is ambiguous — never guesses. At cycle close, updates SYSTEM_MEMORY.md with what was built.

**When to invoke:** At the start of every delivery cycle when the PO has written an intent statement. Also at cycle close.

---

### `guardian` — Automated Gate Review

**File:** [guardian.md](guardian.md)

The IDF Guardian. Reviews Builder output against gate criteria and produces a gate report of exactly three paragraphs: what was built, signals (tests, security, performance, cost, client impact), and a pass/flag/fail decision with a next-cycle suggestion. The report is written for the PO, not the developer.

**When to invoke:** After Builder agents complete a task, before the PO gate review.

---

### `requirements-analyst` — Requirements Processing

**File:** [requirements-analyst.md](requirements-analyst.md)

Processes new client input and change requests. Compares against the current polaris.md, identifies impacted deliverables, flags scope changes, and guides documentation updates with version bumps.

**When to invoke:** When new client requirements or change requests arrive.

---

### `incident-responder` — Production Incident Response

**File:** [incident-responder.md](incident-responder.md)

Emergency response agent. Triages a production incident (rollback via flag vs. hotfix branch), guides containment, and writes the incident drift-register entry. Reads `feature-governance.md` to identify which Live-ON flags are in scope.

**When to invoke:** When a live feature is causing a production incident or a critical bug is found post-merge.

---

### `release-manager` — Release Coordination

**File:** [release-manager.md](release-manager.md)

Coordinates production release after guardian PASS. Runs the pre-release checklist, generates release notes from the intent-log and gate report, guides PO through flag activation (Pending-OFF → Live-ON), manages the 24-hour monitoring window, and triggers orchestrator cycle close.

**When to invoke:** After guardian produces a PASS gate report and the PO is ready to release.

---

### `drift-analyst` — Cross-Cycle Drift Analysis

**File:** [drift-analyst.md](drift-analyst.md)

Retrospective analysis agent. Reads intent-log, gate-reports, and drift-register across a window of recent cycles to identify recurring drift patterns. Produces drift-register entries and recommends capability file improvements.

**When to invoke:** Every 10–20 cycles, or when gate first-pass rate drops below 60% for two consecutive cycles. Typically run as part of Context Reset.

---

### `dependency-broker` — Cross-Team Dependency Management

**File:** [dependency-broker.md](dependency-broker.md)

Manages cross-team dependencies detected during orchestrator decomposition. Classifies blockers vs. anticipatory dependencies, drafts structured PO communication briefs, updates `dependencies.md`, and escalates if blockers persist past two cycles.

**When to invoke:** When the orchestrator detects a cross-team dependency during cycle decomposition.

---

### `project-adoption` — Adopt Template Into Existing Project

**File:** [project-adoption.md](project-adoption.md)

Brings the project-template structure into an existing project that was not originally bootstrapped from this template. Reads the codebase automatically (package.json, csproj, Dockerfile, git history, README) to extract context before asking any questions. Confirms gaps through targeted questions, presents an adoption plan, and creates all template files (docs, agents, skills, IDF artifacts, hooks) populated with real project data. Never overwrites existing project files.

**When to invoke:** When cloning or copying this template into an existing project root to add living docs, AI context files, and IDF delivery infrastructure.

---

### `adopt` — Bootstrap Sibling Project *(project-template workspace only)*

**File:** [../.claude/agents/adopt.md](../.claude/agents/adopt.md)

Available as the `/adopt` command when `project-template` is open as the workspace. Lists sibling projects (i.e. projects in the same parent folder as `project-template`), runs `bootstrap-claude.ps1` to copy the template structure into the chosen one, and then executes the full Flow B wizard (project-adoption agent) — all in a single guided session.

**When to invoke:** Open `project-template` in Claude Code and call `/adopt` when you want to install the template structure into a sibling project.
