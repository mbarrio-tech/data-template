---
version: 1.0
status: draft
last-updated: YYYY-MM-DD
owner: "[QA Lead / Tech Lead]"
---

# Test Strategy

> Defines the testing approach, coverage targets, test types, and CI integration for this project.
> Update when new test suites are added or coverage targets change: bump `version` in frontmatter.

## Testing Principles

1. Tests are written before or alongside production code (TDD where applicable)
2. Every public interface has automated tests
3. CI pipeline blocks merges until all tests pass
4. Flaky tests are fixed or removed — they are never ignored

## Test Types and Ownership

| Type | Tooling | Ownership | Run On |
|---|---|---|---|
| Unit | [e.g. xUnit / Jest / pytest] | Developer | Every commit |
| Integration | [e.g. xUnit + TestContainers] | Developer | PR validation |
| End-to-end | [e.g. Playwright / Cypress] | QA | Nightly |
| Security (SAST) | [e.g. SonarQube] | DevOps | PR merge |
| Performance | [e.g. k6 / JMeter] | Developer + QA | On demand |

## Coverage Targets

| Layer | Target | Current |
|---|---|---|
| Unit | 80% | TBD |
| Integration | 60% | TBD |
| E2E critical paths | 100% | TBD |

## Critical Test Paths

The following paths must have end-to-end test coverage at all times:

1. [e.g. User authentication and session management]
2. [e.g. Core AI inference request and response flow]
3. [e.g. Data persistence and retrieval]

## CI Integration

| Pipeline Stage | Gate | Action on Failure |
|---|---|---|
| PR validation | Unit + integration tests green | Block merge |
| Merge to main | Full test suite + SAST | Block deployment |
| Nightly | E2E + performance baseline | Notify team channel |

## Test Environments

| Environment | Purpose | Who Has Access |
|---|---|---|
| Local (dev) | Unit + integration | All developers |
| Dev / Staging | Integration + E2E | Dev + QA team |
| Production | Smoke tests only | Lead + DevOps |

## Test Data Strategy

[Describe how test data is managed — e.g. factories, fixtures, anonymized production data, mocked external services]

## CI Pipeline Files

Add your CI/CD pipeline files here at inception. The structure below applies regardless of provider (GitHub Actions, GitLab CI, Azure DevOps, etc.):

- `pipelines/pr-validation.yml` — PR gate: lint → unit + integration tests → SAST → bundle size
- `pipelines/deploy.yml` — Deployment: build → staging → smoke tests → production (approval gate)

The PR validation pipeline must implement the gates defined in the CI Integration table above.

## Change Log

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0 | YYYY-MM-DD | [Author] | Initial test strategy from inception |
