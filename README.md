# project-template

A cloneable project template for AI-driven development teams using Claude Code. Provides living documentation, AI context files, agents, and skills — ready in minutes.

There are **two ways to use this template:**

| Flow | When to use |
|---|---|
| [Flow A — New project](#flow-a--new-project-from-scratch) | Starting a brand new project with no existing codebase |
| [Flow B — Existing project](#flow-b--adopt-into-an-existing-project) | Bringing this structure into a project that already exists |

---

## Flow A — New Project From Scratch

Use this flow when cloning this template to start a project from zero.

### 1. Clone this repository

```bash
git clone <your-repo-url>
cd project-template
```

### 2. Start Claude Code — setup runs automatically

Open Claude Code in the cloned folder. The session-start hook detects that the project hasn't been bootstrapped and Claude will immediately offer:

> "This project-template has not been set up yet. Which flow do you want to run? Flow A for a new project from scratch or Flow B to adopt into an existing project."

Select **Flow A**. The inception agent starts automatically — asks 8 questions, accepts the validated Intent Document from product, populates all docs and AI context files, and guides the first commit.

### 3. Start working

Claude Code automatically loads project context every session via `CLAUDE.md`:

- `docs/polaris/polaris.md` — client vision and deliverables
- `docs/architecture/architecture.md` — tech stack and design decisions
- `docs/security/security.md` — security requirements and controls
- `docs/test/test.md` — testing strategy and coverage targets
- `docs/CHANGELOG.md` — recent significant changes
- `skills/brainstorming/SKILL.md` — always-on: design before code
- `skills/verification-before-completion/SKILL.md` — always-on: evidence before claims

No configuration needed. Open Claude Code and start.

---

## Flow B — Adopt Into an Existing Project

Use this flow when the project codebase already exists and you want to add the template's living docs, agents, skills, and IDF delivery infrastructure to it.

### 1. Clone this template inside the existing project

Navigate to the root of the existing project and run:

```bash
# From inside the existing project root
git clone <this-template-repo-url> _template
```

Or simply copy the contents of this repository into the project root (without overwriting existing files).

### 2. Start Claude Code — setup runs automatically

Open Claude Code in the project root (with the template files present). The session-start hook detects that the project hasn't been bootstrapped and Claude will immediately offer:

> "This project-template has not been set up yet. Which flow do you want to run? Flow A for a new project from scratch or Flow B to adopt into an existing project."

Select **Flow B**. The project-adoption agent starts automatically and will:
1. **Read the existing codebase** — detect tech stack, dependencies, git history, existing docs
2. **Confirm context** — ask targeted questions to fill in what it could not infer automatically
3. **Present an adoption plan** — show exactly what files will be created and what will be skipped
4. **Create all template files** — populated with real project data, never overwriting existing files

> **Safe by design:** the adoption agent only creates new files. It never deletes, overwrites, or modifies files that already exist in your project.

### 3. Review and commit

After adoption, review the generated docs with your team:
- `docs/polaris/polaris.md` — confirm vision and deliverables with the PO
- `docs/architecture/architecture.md` — fill in any `[TBD]` sections with the Tech Lead
- `docs/SYSTEM_MEMORY.md` — confirm run commands and environment map

Then commit the new files:

```bash
git add docs/ agents/ skills/ hooks/ CLAUDE.md .claude/ .gitignore
git commit -m "chore: adopt project-template v1.1 structure"
```

---

## Repository Structure

```
README.md                              # You are here
CLAUDE.md                              # Claude Code project context — auto-loaded every session
bootstrap-claude.sh                    # Install template into a sibling project (macOS / Linux)
bootstrap-claude.ps1                   # Install template into a sibling project (Windows)
.claude/
├── settings.json                      # Claude Code project settings + cross-platform hook
└── agents/
    └── adopt.md                       # /adopt — bootstrap a sibling project (project-template workspace only)
docs/
├── SYSTEM_MEMORY.md                   # Running project context and cycle log (AI context)
├── CHANGELOG.md                       # Human-readable history of significant changes
├── TEMPLATE_GUIDE.md                  # What to customise, what not to touch, ownership model
├── polaris/
│   ├── polaris.md                    # Client vision, deliverables, acceptance criteria
│   └── archive/                      # Approved baseline snapshots (YYYY-MM-DD.md)
├── architecture/
│   ├── architecture.md               # Tech stack, components, data flows, design decisions
│   └── archive/
├── security/
│   ├── security.md                   # Security requirements, threat model, controls
│   └── archive/
├── test/
│   ├── test.md                       # Testing strategy, coverage targets, CI gates
│   └── archive/
├── idf/                              # IDF delivery artifacts (intent-log, flags, drift, signals…)
├── capability-library/               # Domain-specific instruction sets for Builder agents
├── designs/                          # Brainstorming outputs (YYYY-MM-DD-<topic>-design.md)
└── plans/                            # Implementation plans (YYYY-MM-DD-<feature>.md)
agents/                               # Installable agent templates — copied into target projects
skills/                               # Installable skill templates — copied into target projects
hooks/
├── session-start                     # Hook script: macOS / Linux (bash)
├── session-start.ps1                 # Hook script: Windows (PowerShell)
└── hooks.json                        # Reference copy of the hook configuration
```

> **Why two `agents/` locations?**
> `agents/` at the root contains all agents that are **installed into target projects** when you run `bootstrap-claude.sh` / `bootstrap-claude.ps1`.
> `.claude/agents/` contains agents that are **only available while `project-template` itself is the workspace** (currently only `adopt`).
> This keeps the bootstrap workflow clean — run `/adopt` here, then work in your project.

---

## Versioning Model

Every doc is always the current version. Git is the full change history. No `_latest` suffixes.

Each doc has YAML frontmatter:

```yaml
---
version: 1.0
status: draft        # draft | approved | superseded
last-updated: YYYY-MM-DD
owner: "[Team Lead]"
---
```

**On sprint end or approved milestone:**

```bash
# 1. Copy to archive
cp docs/polaris/polaris.md docs/polaris/archive/2026-03-31.md

# 2. Tag in git
git tag sprint-1-polaris-approved
git push --tags

# 3. Add entry to docs/CHANGELOG.md
```

See `skills/updating-docs/SKILL.md` and `skills/creating-snapshots/SKILL.md` for step-by-step guidance.

---

## Delivery Cycle

Every feature follows the same repeating cycle. There are no exceptions.

```
Client input
  → requirements-analyst        (ingest intent, validate IDF R1, update intent-log)
  → intent-log (PENDING)

Orchestrator
  → reads SYSTEM_MEMORY + capability-library
  → conflict check (active flags, open dependencies)
  → decomposes intent into sequenced task list

Builder agents
  → implement tasks (one subagent per task)
  → code-reviewer reviews each task
  → commits stay behind a feature flag (IDF R3)

Guardian
  → automated checks (tests, lint, secrets, performance, cost)
  → 3-paragraph gate report: what was built / signals / decision

PO Gate Decision
  → FAIL → route back to orchestrator for next cycle
  → FLAG → human review, then PASS or FAIL
  → PASS → release-manager coordinates flag activation

Release Manager
  → pre-release checklist
  → PO flips flag: Pending-OFF → Live-ON
  → 24-hour monitoring window

Orchestrator (cycle close)
  → updates SYSTEM_MEMORY.md cycle log
  → bumps Current Cycle
  → updates Known Patterns
```

### When things go wrong

**Production incident:** invoke the `incident-responder` agent. Rollback via flag first, investigate after.

**Critical bug:** use the `hotfix` skill. Always reproduce before fixing.

**Repeated drift between intent and output:** run the `drift-analyst` agent (every 10–20 cycles or when gate first-pass rate drops below 60%).

---

## Available Agents

| Agent | Purpose | When to Invoke |
|---|---|---|
| `inception` | Bootstrap a new project from an Intent Document | Once, immediately after cloning |
| `orchestrator` | Decompose cycle intent into tasks; close cycles | Start and end of every delivery cycle |
| `guardian` | Automated gate review — produces PASS/FLAG/FAIL report for PO | After Builder agents complete work |
| `onboarding-guide` | Guide a new team member through the project | Each time a new member joins |
| `code-reviewer` | Review a branch for plan alignment and code quality | Before raising a pull request |
| `requirements-analyst` | Ingest new client input, update intent-log | When new client input arrives |
| `incident-responder` | Emergency response for production incidents | When a live feature causes an incident |
| `release-manager` | Coordinate flag activation and cycle close | After guardian PASS and PO approval |
| `drift-analyst` | Analyse intent-to-output drift across cycles | Every 10–20 cycles or when gate rate drops |
| `dependency-broker` | Manage cross-team dependencies and blockers | When orchestrator detects external dependency |

See [agents/README.md](agents/README.md) for full invocation instructions.

---

## Available Skills

Skills are read by Claude Code when the situation matches. Always-on skills are auto-loaded via `CLAUDE.md`.

| Skill | Always-on | When to Use |
|---|---|---|
| `brainstorming` | ✅ | Before any feature work — design gate |
| `verification-before-completion` | ✅ | Before claiming any task is done |
| `writing-plans` | — | Creating a structured implementation plan |
| `subagent-driven-development` | — | Executing a plan autonomously task by task |
| `dispatching-parallel-agents` | — | Independent problems that can run simultaneously |
| `requesting-code-review` | — | Triggering the code-reviewer agent on demand |
| `finishing-a-development-branch` | — | Merging, abandoning, or keeping a branch |
| `using-git-worktrees` | — | Isolating feature work in a worktree |
| `hotfix` | — | Production incident — rollback or hotfix branch |
| `debugging` | — | Systematic bug investigation and fix |
| `database-migrations` | — | Any schema change — expand/contract pattern |
| `project-inception` | — | Project not yet bootstrapped after cloning |
| `onboarding` | — | New team member joining the project |
| `updating-docs` | — | A living doc needs to reflect a new decision |
| `creating-snapshots` | — | Sprint end, milestone approval, or sign-off |
| `context-reset` | — | Every 5–10 cycles or when gate rate is declining |
| `capability-harvest` | — | Repeated pattern detected — encode it |

---

## Contributing to the Template

To improve this template for future projects:

1. Create a branch from main
2. Make changes with clear, descriptive commit messages
3. Add an entry to `docs/CHANGELOG.md` describing what changed and why
4. Raise a pull request for review
