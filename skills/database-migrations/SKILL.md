---
name: database-migrations
description: Safe database schema migration discipline. Covers the expand/contract pattern, sequencing rules within IDF cycles, idempotency requirements, and anti-patterns.
---

# Database Migrations

Use this skill whenever a task involves changing the database schema: adding columns, renaming columns, dropping columns, adding tables, modifying constraints, or adding indexes.

## The Core Problem

Feature flags enable rollback for code changes. **They do not enable rollback for schema changes.** A deployed migration cannot be undone by flipping a flag. This makes migrations the one class of change that fundamentally breaks the IDF R3 rollback model if not handled correctly.

The solution is the **expand/contract pattern**: every schema change is split into two migrations deployed in separate cycles.

---

## The Expand/Contract Pattern

### Expand Phase (Cycle N)

Add the new structure to the schema without removing anything old.

Examples:
- Adding a new column: add the column as nullable with a default value
- Renaming a column: add the new column, keep the old one
- Adding a new table: add it, leave existing tables untouched
- Changing a column type: add a new column with the new type

After the expand migration is deployed, update the code to write to both old and new structures. Old reads still work. New reads begin using the new structure.

### Contract Phase (Cycle N+1 or later)

Remove the old structure after the code no longer references it.

Examples:
- Renamed column: remove the old column after code no longer reads it
- Type change: remove the old column after backfill and code switchover are confirmed
- Removed feature: remove the old table after the feature is fully Dead-OFF

**Never combine expand and contract in a single migration.**

---

## Sequencing in Orchestrator Task Lists

Migrations are **forward-only deployments** — they are not behind feature flags.

When a cycle includes schema changes, the orchestrator task list must sequence them first:

1. Migration task (expand phase) — no dependencies, deployed immediately
2. Code tasks that depend on the new schema — can only start after migration is confirmed deployed
3. Flag activation — only after both migration and code are in production

Tell the orchestrator: "Migration tasks have no dependencies and must be sequenced before any code tasks that use the new schema."

---

## Idempotency Requirement

Every migration must be idempotent: running it twice must produce the same result as running it once.

Use conditional guards:

```sql
-- SQL example
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name VARCHAR(255);
```

```csharp
// EF Core example — always check before adding
if (!migrationBuilder.ActiveProvider.Contains("InMemory"))
{
    migrationBuilder.AddColumn<string>("display_name", "users", nullable: true);
}
```

Non-idempotent migrations will break in CI environments where the database may already be at the target state.

---

## Migration Checklist

Before marking a migration task complete:

- [ ] Migration is a pure expand (adding) or pure contract (removing) — not both
- [ ] Migration is idempotent (safe to run twice)
- [ ] Migration has been tested against a local database from a clean state
- [ ] Migration has been tested against a database already at the previous state (upgrade path)
- [ ] Any code changes that depend on the new schema are behind a feature flag
- [ ] No code that was removed in the same cycle still references the old schema
- [ ] Migration is committed separately from the code changes that use it

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Correct Approach |
|---|---|---|
| Rename in one migration | Old code breaks immediately | Expand: add new column → Contract: remove old after code updated |
| Drop column in same cycle as feature flag flip | Rollback becomes impossible | Contract phase is always a separate cycle |
| Non-nullable column with no default | All existing rows fail insert | Always add with default or as nullable |
| Single migration that expands and contracts | No safe rollback point | Two migrations, two cycles |
| Migration depends on seed data in code | Order dependency creates fragile deploys | Seed data migrations are separate from schema migrations |

---

## Rollback vs. Rollforward

Because migrations are forward-only, "rollback" means different things:

- **Within the monitoring window:** if the expand migration caused issues, the rollback is to deploy a contract migration (remove what was added). This is a new migration, not a revert.
- **After the monitoring window:** always rollforward. Identify the issue, write a new migration in the next cycle.

Never use `Down()` migrations in production unless the team has explicitly tested and verified the down path. Most `Down()` migrations are untested and unsafe.
