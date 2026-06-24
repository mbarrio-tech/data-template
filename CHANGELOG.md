# Changelog

All significant changes to project documentation and structure are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Dates use ISO 8601 (YYYY-MM-DD).

---

## [Unreleased]

---

## [Template v1.0] - 2026-03-31

### Added

- `docs/polaris/polaris.md` — client vision, deliverables, and acceptance criteria template with YAML frontmatter versioning
- `docs/architecture/architecture.md` — tech stack, system components, data flows, and ADR log template
- `docs/security/security.md` — security requirements, STRIDE threat model, OWASP Top 10 coverage, and controls template
- `docs/test/test.md` — testing strategy, coverage targets, and CI integration template
- `docs/*/archive/` folders — for approved baseline snapshots (YYYY-MM-DD.md naming)
- `CLAUDE.md` — Claude Code project context template (populated by inception agent)
- `agents/inception.md` — project bootstrap agent: processes Intent Document and populates all template placeholders
- `agents/onboarding-guide.md` — new team member guide agent
- `agents/code-reviewer.md` — code review agent: polaris alignment, security, test coverage, code quality
- `agents/requirements-analyst.md` — requirements processing agent: scope impact assessment and polaris updates
- `agents/README.md` — agent index with invocation instructions for Claude Code
- `skills/project-inception/SKILL.md` — when and how to run project inception
- `skills/onboarding/SKILL.md` — new member onboarding workflow (day 1 / week 1)
- `skills/updating-docs/SKILL.md` — when and how to update living docs with frontmatter version bumps
- `skills/creating-snapshots/SKILL.md` — snapshot naming convention, git tag workflow, CHANGELOG entry
- `hooks/session-start` — bash script that reads polaris.md and injects project context into every Claude Code session
- `hooks/hooks.json` — Claude Code SessionStart hook configuration reference
- `README.md` — getting started guide: clone, run inception agent, versioning model, team workflow

### Notes for teams using this template

- Run the inception agent immediately after cloning to replace all placeholder values
- All `[placeholder]` text is populated by the inception agent from your validated Intent Document
- See `README.md` for the full getting started guide and hook configuration instructions
