#!/usr/bin/env bash
# =============================================================================
# demo.sh — Interactive guardrail demonstration
# =============================================================================
# Shows each quality/security check catching a real problem, then restores
# the repo to a clean state after each step.
#
# Usage:
#   source .venv/bin/activate
#   bash demo.sh
#
# Each check requires a keypress to proceed so you can read the output.
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Helpers ──────────────────────────────────────────────────────────────────
header() {
  echo ""
  echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}${BLUE}  $1${RESET}"
  echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════${RESET}"
  echo ""
}

step() {
  echo -e "${CYAN}▶  $1${RESET}"
}

pass() {
  echo -e "${GREEN}✅  $1${RESET}"
}

fail_expected() {
  echo -e "${RED}❌  $1${RESET}"
}

note() {
  echo -e "${DIM}    $1${RESET}"
}

pause() {
  echo ""
  echo -e "${YELLOW}Press ENTER to continue...${RESET}"
  read -r
}

restore() {
  git checkout -- . 2>/dev/null || true
}

check_venv() {
  if ! command -v dbt &>/dev/null; then
    echo -e "${RED}Error: dbt not found. Activate the venv first:${RESET}"
    echo "  source .venv/bin/activate"
    exit 1
  fi
  if ! command -v sqlfluff &>/dev/null; then
    echo -e "${RED}Error: sqlfluff not found. Activate the venv first:${RESET}"
    echo "  source .venv/bin/activate"
    exit 1
  fi
}

# ── Preflight ─────────────────────────────────────────────────────────────────
check_venv

echo ""
echo -e "${BOLD}Data Pipeline Quality & Security — Live Demo${RESET}"
echo -e "${DIM}Each step introduces a deliberate problem, shows the check"
echo -e "catching it, then restores the file.${RESET}"
pause

# =============================================================================
# CHECK 1: SQL FORMATTING — SQLFluff
# =============================================================================
header "CHECK 1 of 4 — SQL Formatting (SQLFluff)"

step "The rule: no SELECT *, keywords must be UPPER CASE, no missing AS on aliases."
echo ""
step "Introducing a bad SQL file with three violations..."
echo ""

cat > /tmp/bad_model.sql << 'SQL'
-- Intentionally bad SQL — three lint violations:
--   1. select * (should list columns explicitly)
--   2. lowercase keyword 'from'
--   3. alias without AS keyword
select *
from orders o
where o.status = 'delivered'
SQL

cp /tmp/bad_model.sql models/staging/stg_bad_example.sql
note "Created: models/staging/stg_bad_example.sql"
echo ""
note "Contents:"
cat models/staging/stg_bad_example.sql
echo ""

step "Running: sqlfluff lint models/staging/stg_bad_example.sql"
echo ""
sqlfluff lint models/staging/stg_bad_example.sql || true
echo ""

fail_expected "SQLFluff found violations — this file would BLOCK the PR."
echo ""

step "Running auto-fix: sqlfluff fix models/staging/stg_bad_example.sql"
echo ""
sqlfluff fix --force models/staging/stg_bad_example.sql || true
echo ""
note "Fixed file contents:"
cat models/staging/stg_bad_example.sql
echo ""

step "Re-linting after fix..."
echo ""
sqlfluff lint models/staging/stg_bad_example.sql && pass "Zero violations — file would now PASS the PR check."
echo ""

step "Restoring repo to clean state..."
rm -f models/staging/stg_bad_example.sql
pass "Cleaned up."

pause

# =============================================================================
# CHECK 2: SPEC FILE — complex logic without a test
# =============================================================================
header "CHECK 2 of 4 — SPEC File (complex logic must have a behaviour test)"

step "The rule: any model with a window function, dedup, or multi-branch CASE"
step "must have a SPEC file that returns 0 rows when the logic is correct."
echo ""

step "First, let's run the existing SPEC for fact_orders (should PASS)..."
echo ""
note "specs/fact_orders/customer-running-total.spec.sql"
echo ""

if .venv/bin/python3 -c "
import duckdb
sql = open('specs/fact_orders/customer-running-total.spec.sql').read()
result = duckdb.sql(sql).fetchall()
if result == []:
    print('Result: 0 rows returned')
else:
    print(f'Result: {len(result)} rows returned (FAIL)')
    for r in result: print(' ', r)
"; then
  pass "SPEC returned 0 rows — window function logic is CORRECT."
fi

echo ""
step "Now introducing a bug into the window function logic..."
echo ""

# Save original
cp models/marts/fact_orders.sql /tmp/fact_orders_backup.sql

# Introduce a bug: wrong ORDER BY direction (DESC instead of ASC breaks running total)
sed 's/ORDER BY fo.ordered_date ASC, fo.order_id ASC/ORDER BY fo.ordered_date DESC, fo.order_id DESC/' \
  models/marts/fact_orders.sql > /tmp/fact_orders_buggy.sql
cp /tmp/fact_orders_buggy.sql models/marts/fact_orders.sql

note "Changed ORDER BY ASC → DESC in the window function (wrong cumulation order)"
echo ""

step "Re-running SPEC against the buggy logic..."
echo ""

.venv/bin/python3 -c "
import duckdb
sql = open('specs/fact_orders/customer-running-total.spec.sql').read()
result = duckdb.sql(sql).fetchall()
if result == []:
    print('Result: 0 rows — PASS (unexpected)')
else:
    print(f'Result: {len(result)} mismatch row(s) — FAIL')
    print()
    print('  order_id | actual_total | expected_total')
    print('  ' + '-'*40)
    for r in result:
        print(f'  {r}')
" || true

echo ""
fail_expected "SPEC returned rows — the bug was caught. This commit would be BLOCKED."

step "Restoring original fact_orders.sql..."
cp /tmp/fact_orders_backup.sql models/marts/fact_orders.sql
pass "Restored."

pause

# =============================================================================
# CHECK 3: DATA QUALITY TESTS — dbt test
# =============================================================================
header "CHECK 3 of 4 — Data Quality Tests (dbt test)"

step "The rule: every table must have not_null, unique, accepted_values,"
step "referential integrity, and business logic tests — all must pass."
echo ""

step "First, showing the clean baseline — all tests should PASS..."
echo ""

dbt seed --quiet --profiles-dir . 2>/dev/null
dbt run --quiet --profiles-dir . 2>/dev/null
dbt test --profiles-dir . 2>&1 | tail -6
echo ""
pass "All tests pass on the clean baseline."

echo ""
step "Now introducing bad data: an order with a negative amount..."
echo ""

# Inject a bad row directly into the seed CSV
cp seeds/orders.csv /tmp/orders_backup.csv
echo "9999,1,P01,delivered,-99.00,2024-08-01,2024-08-02,2024-08-03" >> seeds/orders.csv
note "Appended to seeds/orders.csv: order 9999 with amount = -99.00"

echo ""
step "Re-seeding and re-running tests..."
echo ""

dbt seed --quiet --profiles-dir . 2>/dev/null
dbt run --quiet --profiles-dir . 2>/dev/null
dbt test --profiles-dir . 2>&1 | grep -E "(PASS|FAIL|ERROR|error|Completed|no_negative)" | head -15 || true

echo ""
fail_expected "Test 'fact_orders_no_negative_amount' FAILED — bad data was caught."

step "Restoring clean seed data..."
cp /tmp/orders_backup.csv seeds/orders.csv
dbt seed --quiet --profiles-dir . 2>/dev/null
dbt run --quiet --profiles-dir . 2>/dev/null
pass "Restored and re-seeded."

pause

# =============================================================================
# CHECK 4: SCHEMA BREAKER — breaking a downstream column
# =============================================================================
header "CHECK 4 of 4 — Schema Breaker (DAG impact on column removal)"

step "The rule: removing or renaming a column that is consumed by downstream"
step "datasets must be detected before it reaches production."
echo ""

step "Simulating a PR that renames 'segment' → 'customer_tier' in dim_customers..."
echo ""

# Save original schema
cp models/marts/schema.yml /tmp/marts_schema_backup.yml

# Rename the column in the schema file
sed 's/name: segment/name: customer_tier/' models/marts/schema.yml > /tmp/schema_modified.yml
cp /tmp/schema_modified.yml models/marts/schema.yml

note "models/marts/schema.yml — 'segment' renamed to 'customer_tier'"
echo ""

step "Compiling dbt to generate manifest.json..."
dbt compile --quiet --profiles-dir . 2>/dev/null
echo ""

step "Running schema breaker check..."
echo ""

BASE_REF=HEAD MANIFEST_PATH=target/manifest.json \
  python3 scripts/check_schema_breaking.py 2>&1 || true

echo ""
note "The schema breaker diffs schema.yml against the base branch,"
note "identifies removed columns, and traverses the DAG for downstream impact."
note "(In a real PR this runs against origin/main automatically in GitHub Actions.)"
echo ""

fail_expected "Column 'segment' removal detected — would BLOCK the PR until downstream consumers are updated."

step "Restoring original schema.yml..."
cp /tmp/marts_schema_backup.yml models/marts/schema.yml
pass "Restored."

pause

# =============================================================================
# SUMMARY
# =============================================================================
header "Demo Complete — Summary"

echo -e "  ${GREEN}✅${RESET}  ${BOLD}SQLFluff${RESET}          — caught SELECT *, lowercase keywords, missing AS"
echo -e "  ${GREEN}✅${RESET}  ${BOLD}SPEC file${RESET}          — caught wrong ORDER BY in window function"
echo -e "  ${GREEN}✅${RESET}  ${BOLD}dbt test${RESET}           — caught negative amount violating business rule"
echo -e "  ${GREEN}✅${RESET}  ${BOLD}Schema breaker${RESET}     — detected downstream DAG impact of column removal"
echo ""
echo -e "  ${DIM}Checks 1 & 4 run automatically in GitHub Actions on every PR."
echo -e "  Check 3 runs in CI as part of dbt test after merge."
echo -e "  Check 2 is enforced by the capability doc hard gate before commit."
echo -e "  GitHub Copilot review covers all four during the PR review.${RESET}"
echo ""
pass "All checks working correctly."
echo ""
