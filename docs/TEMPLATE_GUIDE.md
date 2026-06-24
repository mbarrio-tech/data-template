# Template Guide

> For humans only — not loaded by Claude Code.
> Read this before modifying framework files.

This guide explains what teams can customise freely, what should not be modified without understanding the framework, and how to reset the template history for a clean project start.

---

## What Teams Customise Freely

These files and folders are project-specific. Fill them in, extend them, and make them your own:

| What | Where | Notes |
|---|---|---|
| Project content | `docs/polaris/polaris.md` | Vision, deliverables, acceptance criteria |
| Architecture decisions | `docs/architecture/architecture.md` | Tech stack, components, ADRs |
| Security controls | `docs/security/security.md` | Threat model, controls, compliance |
| Test strategy | `docs/test/test.md` | Tooling, coverage targets, CI gates |
| IDF artifacts | `docs/idf/*.md` | Client signals, intent log, drift register, flags |
| Capability library | `docs/capability-library/` | Add domain-specific capability files as patterns emerge |
| Design docs | `docs/designs/` | Created by brainstorming skill — project-specific |
| Implementation plans | `docs/plans/` | Created by writing-plans skill — project-specific |
| Agent content | `agents/*.md` | Add questions, extend checklists, add project-specific checks |
| Skills content | `skills/*/SKILL.md` | Extend with project conventions |
| CI/CD pipelines | `pipelines/` | Add at inception for your project's stack and CI provider |
| `.gitignore` | `/.gitignore` | Extend for your specific stack |

---

## What Not to Modify Without Understanding the Framework

Modifying these files incorrectly can break agent behaviour or context loading:

| What | Why |
|---|---|
| `CLAUDE.md` `@` import directives | These load living docs into every session — removing them breaks context |
| `CLAUDE.md` "Always Active Rules" section | These rules apply to every agent in every session |
| `docs/SYSTEM_MEMORY.md` section headers | Agents parse specific section names — changing headers breaks agent reads |
| IDF artifact frontmatter | `version`, `status`, `owner`, `idf-ref` fields are used by agents |
| `.claude/settings.json` permissions | The deny list prevents destructive commands — do not empty it |

If you need to change these, read the file first, understand what it does, and make the minimal targeted change.

---

## Agent and Skill Customisation

**Add agents:** Copy an existing agent file as a starting point. Follow the frontmatter format. Register in `agents/README.md` and `CLAUDE.md`.

**Add skills:** Create a new folder under `skills/` with a `SKILL.md` file. Register in `CLAUDE.md` skills table. Mark as always-on only if it should apply to every single task.

**Extend existing agents:** The 8 inception questions are a minimum — add project-specific questions. Guardian checks can be extended with project-specific automated checks. Code-reviewer criteria can be extended with project-specific architectural rules.

---

## Ownership Model

| File / Area | Owner |
|---|---|
| `docs/polaris/` | Product Owner |
| `docs/architecture/` | Tech Lead |
| `docs/security/` | Tech Lead + Security |
| `docs/test/` | QA Lead / Tech Lead |
| `docs/idf/intent-log.md` | Orchestrator (writes) + PO (owns intent) |
| `docs/idf/client-signals.md` | Product Owner |
| `docs/idf/feature-governance.md` | PO (toggle) + Builder (creates flag) + Tech Lead (cleanup) |
| `docs/idf/drift-register.md` | Guardian + Drift Analyst (writes) + Tech Lead (reviews) |
| `docs/idf/outcome-register.md` | Release Manager (writes) + PO (confirms) |
| `docs/SYSTEM_MEMORY.md` | Orchestrator (writes) + Tech Lead (governs) |
| `CLAUDE.md` | Tech Lead |
| `agents/`, `skills/` | Tech Lead |
| `.claude/settings.json` | Tech Lead |

---

## CHANGELOG Reset at Inception

The template ships with a `[Template v1.0]` entry in `docs/CHANGELOG.md`. At inception, the inception agent:

1. Archives the template changelog to `docs/archive/TEMPLATE_CHANGELOG.md`
2. Resets `docs/CHANGELOG.md` to start with `[Project v1.0] — Inception — [Project Name]`

After inception, `docs/CHANGELOG.md` is your project's history only. Template history is preserved in `docs/archive/TEMPLATE_CHANGELOG.md`.

---

## Template Version History

This is project-template `v1.1`. Key additions in this version:

- `.gitignore` — secret and artifact exclusions
- `.claude/settings.json` — destructive command deny list + hook activation
- `hooks/session-start` — live repo state injection
- `skills/hotfix/` — emergency rollback and hotfix branch workflow
- `skills/debugging/` — reproduce-first, hypothesis-driven debugging
- `skills/database-migrations/` — expand/contract pattern
- `agents/incident-responder.md` — production incident response
- `agents/release-manager.md` — flag activation and cycle close coordination
- `agents/drift-analyst.md` — cross-cycle drift pattern analysis
- `agents/dependency-broker.md` — cross-team dependency management
- `docs/idf/outcome-register.md` — post-release outcome tracking
- `docs/SYSTEM_MEMORY.md` — Known Open Risks + Environment Map sections (moved from root)
- `docs/architecture/architecture.md` — Data Migration Strategy section
- `docs/idf/feature-governance.md` — Emergency Rollback procedure
- `README.md` — Delivery Cycle workflow documentation
- `CLAUDE.md` — Always Active Rules section
