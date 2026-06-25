# Makefile — shorthand commands for data-pipeline-example
# Assumes .venv is already activated, or uses .venv/bin directly.

VENV_DBT      := .venv/bin/dbt
VENV_SQLFLUFF := .venv/bin/sqlfluff
VENV_DUCKDB   := .venv/bin/python3 -c "import duckdb"

.PHONY: setup run test lint spec-orders spec-customers all clean

## First-time environment setup
setup:
	bash setup.sh

## Load seed CSV files into DuckDB
seed:
	$(VENV_DBT) seed --profiles-dir .

## Build all models (staging views + mart tables)
run:
	$(VENV_DBT) run --profiles-dir .

## Run all dbt schema tests + singular tests
test:
	$(VENV_DBT) test --profiles-dir .

## SQLFluff lint on all SQL models
lint:
	$(VENV_SQLFLUFF) lint models/

## SQLFluff auto-fix
fix:
	$(VENV_SQLFLUFF) fix models/

## Run SPEC file: customer running total
spec-orders:
	.venv/bin/python3 -c "import duckdb; res = duckdb.sql(open('specs/fact_orders/customer-running-total.spec.sql').read()); print('PASS — 0 rows' if res.fetchall() == [] else ('FAIL', res.fetchall()))"

## Run SPEC file: dim_customers dedup
spec-customers:
	.venv/bin/python3 -c "import duckdb; res = duckdb.sql(open('specs/dim_customers/latest-record-dedup.spec.sql').read()); print('PASS — 0 rows' if res.fetchall() == [] else ('FAIL', res.fetchall()))"

## Run everything in order: seed → run → test → lint → specs
all: seed run test lint spec-orders spec-customers

## Interactive guardrail demo — shows every check catching a real problem
demo:
	bash demo.sh

## Remove generated files
clean:
	rm -rf target/ dev.duckdb dev.duckdb.wal
