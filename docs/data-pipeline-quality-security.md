---
version: 1.0
status: approved
last-updated: 2026-06-25
owner: "[Tech Lead]"
---

# Data Pipeline Quality & Security Initiative

> This document is the human-readable explanation of the three always-active guardrails
> installed in `CLAUDE.md` and `docs/capability-library/`. It describes what each
> guardrail does, why it exists, what Claude checks before marking work complete, and
> what teams need to have in place for the guardrails to function.
>
> For the machine-readable rules that Claude enforces, see the capability files linked in
> each section.

---

## Why This Initiative Exists

Data pipelines fail quietly. A bad SQL transformation ships without error, corrupts a
downstream table, and surfaces two weeks later as a wrong number in a client dashboard.
An untested table passes every CI check and then produces zero rows in production after
a schema change upstream. A public GCS bucket sits unnoticed until a security scan finds
it six months later.

These three guarantees — SQL quality, data quality checks, and infrastructure security —
exist because the cost of catching these problems at merge time is trivially low compared
to the cost of catching them in production. They are not optional improvements; they are
baseline conditions for work to be considered done.

---

## Initiative 1: SQL Quality

**Capability file:** [`docs/capability-library/sql-quality.md`](capability-library/sql-quality.md)

### What it covers

Every SQL file, dbt model, Dataform definition, or pipeline transformation must pass two
checks before it is marked complete: a linting pass and a manual performance review.

### Why both checks are needed

Linting catches mechanical problems — inconsistent casing, `SELECT *`, unqualified table
references — that a static analyser can detect automatically. Performance review catches
logical problems — transformations that run on unfiltered millions of rows before
discarding most of them — that no linter can detect because they require understanding
the data shape.

The two checks are complementary. A query can pass every lint rule and still be an
expensive full-table scan. A query can be well-structured and still have `SELECT *`
slipping in from a rushed edit.

### The lint rules (8 rules)

| Rule | What is checked |
|---|---|
| L001 | SQL keywords in UPPER CASE |
| L002 | Column names and aliases in `snake_case` |
| L003 | No trailing whitespace |
| L004 | No `SELECT *` in production code |
| L005 | All table references fully qualified (`dataset.table`) |
| L006 | Every CTE is actually referenced — no dead code |
| L007 | No secrets or credentials in inline comments |
| L008 | `DISTINCT` only when duplicates are expected and explained |

The linter is run with: `sqlfluff lint <path> --dialect <bigquery|snowflake|spark|...>`

If the project does not yet have a `.sqlfluff` config file, the task is blocked until
the tech lead adds one. Claude will not self-certify a clean lint pass without running
the tool.

### The performance review (filter-first rule and seven other checks)

The most critical check is the **filter-first rule**: `WHERE` clauses must be applied
before any join, window function, or aggregation. The canonical wrong pattern is joining
two full tables and then filtering the result — every row from both tables enters the
join engine before the filter discards most of them. The correct pattern pushes the
filter into a CTE before the join, so only matching rows participate.

The other performance checks cover:

- **Join completeness** — no implicit cross joins, every `JOIN` has an explicit `ON`
- **Partition pruning** — queries against partitioned tables always filter on the
  partition column; functions on partition columns disable pruning and are blocked
- **Aggregation order** — `GROUP BY` runs on the smallest possible dataset after
  filtering, not on the raw table
- **Window function placement** — window functions never appear in `WHERE`; they live
  in a CTE
- **CTE depth** — no CTE nesting deeper than 3 levels without a documented reason
- **Large table strategy** — tables over 1 GB use an incremental (time-window or
  change-data) pattern rather than a full scan every run
- **Meaningless ORDER BY** — `ORDER BY` without `LIMIT` is blocked inside CTEs and
  subqueries

### What Claude checks before marking a SQL task done

1. `sqlfluff lint` exits with zero violations — output shown as evidence
2. Filter-first rule verified for every transformation in the file
3. No `SELECT *` anywhere in production-facing queries
4. Partition pruning confirmed for any query touching a partitioned table
5. No cross joins without a documented intent comment
6. Incremental strategy documented if any source table exceeds 1 GB

---

## Initiative 2: Data Quality Checks

**Capability file:** [`docs/capability-library/data-quality-checks.md`](capability-library/data-quality-checks.md)

### What it covers

Every table produced by the pipeline must have a defined set of quality tests before
it is considered done. The tests must be implemented in the project's testing layer
(dbt `schema.yml` assertions, Dataform `.sqlx` assertions, or equivalent) and must
pass locally before the work is committed.

### Why this is a hard requirement

A table without tests is not a finished table — it is an untested assumption. The first
time a source schema changes, a join key is remapped, or an upstream feed goes empty,
an untested table will silently produce wrong data. By the time the error surfaces in a
dashboard or report, the lineage is hard to trace and the blast radius is large.

Tests are the mechanism that turns "the pipeline ran" into "the pipeline produced correct
data." They are not optional documentation — they are executable guarantees.

### Table tier classification

Not all tables require the same level of testing. The capability defines three tiers:

| Tier | Definition |
|---|---|
| **Critical** | Directly feeds a client-facing report, dashboard, or downstream system |
| **Standard** | Internal pipeline model used by other models |
| **Raw / Staging** | Source extract or light rename — not yet aggregated |

Tests escalate with tier. Critical tables carry the strictest requirements.

### Tests required at every tier

These three test types apply to every table regardless of tier:

**Primary key integrity**
Every table must have `not_null` and `unique` tests on its primary key column(s). A
table with duplicate or null primary keys is broken at the most fundamental level —
no downstream test can compensate for this.

**Accepted values on categorical columns**
Every column with a fixed set of valid values (status, type, category, flag) must have
an `accepted_values` test. When a new value arrives from the source system without a
corresponding test update, the test fails immediately instead of silently propagating
an unknown category into the downstream model.

**Referential integrity on foreign keys**
Every foreign key column must have a relationship test to its parent table. An orphaned
foreign key — an `order_id` that references no row in `dim_orders` — is a data model
violation that corrupts joins and aggregations downstream.

### Additional tests for Critical and Standard tiers

**Row count anomaly detection**
A test that fails when the table row count drops to zero or below a defined threshold.
A table that was non-empty yesterday and is empty today is always a pipeline failure.
This test catches dropped feeds, empty source extracts, and failed upstream runs before
they propagate.

**Not null on business-critical columns**
Beyond the primary key, columns that must never be null in a valid row (amounts,
timestamps, event types) each get a `not_null` test. If a column is intentionally
nullable, a comment must explain when and why.

**Freshness assertion**
Tables loaded on a schedule must declare a freshness threshold. If the most recent
record is older than the configured window (e.g. 24 hours), the pipeline is stale and
the test fails. This is the first defence against silently missed loads.

### Additional tests for Critical tier only

**Business logic assertion**
At least one custom test that encodes a known domain rule as a query. Examples:
no negative order totals, delivery timestamp must follow shipment timestamp, refund
amount cannot exceed original order total. The test is written as a query that returns
rows when the rule is violated — a non-empty result is a failure.

Generic structural tests (not_null, unique) are necessary but not sufficient for a
Critical table. The business logic assertion is what distinguishes a table that is
structurally valid from a table that is semantically correct.

**Column coverage documentation**
Every column in a Critical table must have a plain-English description, a null policy
(never null / nullable — with a reason), and accepted values or range where applicable.
A Critical table without column documentation does not pass the gate.

### Test naming convention

Tests must be named descriptively enough to diagnose the failure without reading the
test body:

| Type | Naming pattern | Example |
|---|---|---|
| Primary key not null | `<table>_pk_not_null` | `fact_orders_pk_not_null` |
| Primary key unique | `<table>_pk_unique` | `fact_orders_pk_unique` |
| Foreign key | `<table>_fk_<parent>` | `fact_orders_fk_customer` |
| Accepted values | `<table>_<column>_accepted_values` | `fact_orders_status_accepted_values` |
| Row count | `<table>_not_empty` | `fact_orders_not_empty` |
| Freshness | `<table>_freshness` | `fact_orders_freshness` |
| Business rule | `<table>_<rule>` | `fact_orders_no_negative_total` |

### What Claude checks before marking a table task done

1. Table tier classified
2. `not_null` + `unique` on all primary key columns — code present
3. `accepted_values` on all categorical columns — code present
4. Referential integrity test on all foreign key columns — code present
5. Row count assertion present (Critical and Standard)
6. Freshness assertion present if schedule-loaded (Critical and Standard)
7. Business logic assertion present with at least one domain rule (Critical only)
8. All columns documented with description and null policy (Critical only)
9. All tests pass: `dbt test -s <model>` or Dataform equivalent — output shown as evidence
10. Test names follow the naming convention

---

## Initiative 3: Terraform Security

**Capability file:** [`docs/capability-library/terraform-security.md`](capability-library/terraform-security.md)

### What it covers

Every Terraform file (`.tf`) that creates or modifies infrastructure must pass a
security checklist and an automated scanner before it is marked complete.

### Why infrastructure security is a hard gate

A misconfigured SQL query wastes compute. A misconfigured Terraform resource can expose
data to the internet, grant an attacker project-wide write access, or leave audit logs
disabled — and none of these are reversible with a feature flag. The moment `terraform
apply` runs, the configuration is live.

The guardrail exists because human reviewers miss things under deadline pressure, and
because the cost of a public bucket or over-privileged service account is not
proportional to the cost of running a scanner.

### Automated scanner requirement

Every Terraform change must be scanned with Checkov (preferred) or tfsec before
committing. The scan must exit with zero HIGH or CRITICAL findings.

```
checkov -d . --framework terraform
```

If the project does not yet have a scanner configured in CI, the task is blocked until
the tech lead adds it. Claude will not self-certify a passing scan without running the
tool.

### The nine security controls

**1. No secrets in code**
No passwords, API keys, tokens, or connection strings in any `.tf` file or committed
`terraform.tfvars`. All sensitive values come from a secret manager reference (GCP
Secret Manager, AWS Secrets Manager, Azure Key Vault) or from CI/CD environment
variables. Variables that hold secrets are declared with `sensitive = true`.

**2. Principle of least privilege on IAM**
Service accounts and IAM bindings grant only the minimum permissions required for the
specific resource and operation. `roles/owner` and `roles/editor` are blocked in
production. Pipeline runtime service accounts are separate from infrastructure
management service accounts.

**3. No public storage**
No GCS bucket, S3 bucket, or Azure Blob container has public access enabled.
GCS buckets must have `uniform_bucket_level_access = true` and
`public_access_prevention = "enforced"`. S3 buckets must have all four
`block_public_*` settings set to `true`. No ACL grants access to `allUsers` or
`allAuthenticatedUsers`.

**4. Encryption at rest**
All storage resources — buckets, BigQuery datasets, database instances — use encryption
at rest. For regulated data, customer-managed encryption keys (CMEK) are required
rather than cloud-provider default managed keys.

**5. Encryption in transit**
All external-facing load balancers and APIs enforce TLS 1.2 minimum. SSL policies are
set explicitly on Google load balancers. Database connections require SSL/TLS (`require_ssl = true`). No provider configuration sets `insecure = true`.

**6. Network isolation**
All pipeline compute resources (VMs, Cloud Run, Dataproc) are deployed inside a VPC.
Firewall rules follow deny-by-default with explicit allows. No firewall rule allows
inbound traffic from `0.0.0.0/0` on ports other than 80 and 443. Database instances
use private IP only — `ipv4_enabled = false`.

**7. Terraform state security**
Remote state backend is configured — no local `terraform.tfstate` committed to the
repository. State storage is encrypted and not publicly accessible. State backend access
is restricted to CI/CD and authorised engineers, not the pipeline runtime service
account. State locking is enabled.

**8. Logging and audit trail**
Data access audit logs are enabled for BigQuery, Cloud Storage, and any service
handling PII. Admin activity logs are enabled on all projects. Log export is configured
to a retention destination (30 days minimum; 365 days for regulated data). Terraform
changes are applied only through CI/CD — no manual `terraform apply` from developer
workstations in production.

**9. Resource tagging and labelling**
Every resource carries at minimum: `project`, `environment`, `owner`. Labels are defined
in a shared `locals` block and applied consistently — not hardcoded inline on individual
resources.

### What Claude checks before marking a Terraform task done

1. `checkov -d . --framework terraform` exits with zero HIGH/CRITICAL findings — output shown
2. No secrets in any `.tf` or `.tfvars` file committed to the repo
3. No IAM binding uses `roles/owner`, `roles/editor`, or wildcard permissions
4. All storage resources have public access explicitly blocked
5. All storage and database resources have encryption at rest configured
6. All database instances use private IP only
7. Remote state backend configured with locking
8. Data access audit logs enabled for all services handling pipeline data
9. All resources carry the mandatory labels (`project`, `environment`, `owner`)
10. No firewall rule opens `0.0.0.0/0` on non-web ports

---

## How the Guardrails Are Enforced

### At session start

`CLAUDE.md` `@`-imports all three capability files. Claude reads them at the start of
every session, before any work begins. The "Data Pipeline Guardrails" block in the
Always Active Rules section gives Claude a one-line summary of each gate as a
constant reminder.

### During task execution

Each capability file contains a `<HARD-GATE>` block. When Claude reaches the point of
marking a task complete, this block fires: it requires evidence (scanner output, test
run output) before any completion claim is made. Claiming work is done without running
the verification commands is explicitly prohibited by the
`verification-before-completion` skill, which is also always active.

### At code review

The `code-reviewer` agent inherits these guardrails. A PR that includes SQL files,
pipeline model files, or Terraform files will be checked against the relevant capability
checklist as part of the review. A PR that fails any checklist item does not receive a
PASS from the guardian agent.

---

## Prerequisites for Teams

For the guardrails to function, the following must be in place at project inception:

| Prerequisite | Required by | Owner |
|---|---|---|
| `.sqlfluff` config file in the repo root | SQL Quality | Tech Lead |
| `dbt test` or Dataform assertions runnable locally | Data Quality Checks | Data Engineer |
| `checkov` or `tfsec` installed and configured in CI | Terraform Security | DevOps / Tech Lead |
| Remote Terraform state backend provisioned | Terraform Security | DevOps |
| Secret manager configured (GCP / AWS / Azure) | Terraform Security | DevOps |

If any prerequisite is missing when Claude starts a task in that domain, Claude is
instructed to block the task and ask the tech lead to set it up before proceeding.

---

## Relationship to Other Framework Documents

| Document | Relationship |
|---|---|
| [`docs/capability-library/sql-quality.md`](capability-library/sql-quality.md) | Machine-readable rules for Initiative 1 — Claude reads this |
| [`docs/capability-library/data-quality-checks.md`](capability-library/data-quality-checks.md) | Machine-readable rules for Initiative 2 — Claude reads this |
| [`docs/capability-library/terraform-security.md`](capability-library/terraform-security.md) | Machine-readable rules for Initiative 3 — Claude reads this |
| [`CLAUDE.md`](../CLAUDE.md) | Loads the three capability files and summarises the guardrails in Always Active Rules |
| [`docs/test/test.md`](test/test.md) | Testing strategy — data quality checks are part of the test suite for pipeline models |
| [`docs/security/security.md`](security/security.md) | Project-level security requirements — Terraform controls implement the controls defined here |
| [`skills/verification-before-completion/SKILL.md`](../skills/verification-before-completion/SKILL.md) | Enforces evidence-before-claims across all completion gates |

---

## Change Log

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0 | 2026-06-25 | [Author] | Initial document — covers SQL quality, data quality checks, and Terraform security guardrails |
