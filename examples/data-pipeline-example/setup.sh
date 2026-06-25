#!/usr/bin/env bash
# setup.sh — one-time environment setup for data-pipeline-example
# Run once from the repo root: bash setup.sh
set -euo pipefail

PYTHON_BIN=""
REQUIRED_MINOR=12   # dbt supports 3.9–3.12

echo "==> Looking for Python 3.12..."

# 1. Try Homebrew python@3.12
if brew list python@3.12 &>/dev/null 2>&1; then
  PYTHON_BIN="$(brew --prefix python@3.12)/bin/python3.12"
fi

# 2. Try pyenv
if [[ -z "$PYTHON_BIN" ]] && command -v pyenv &>/dev/null; then
  if pyenv versions --bare | grep -q "^3\.12\."; then
    PYTHON_BIN="$(pyenv root)/versions/$(pyenv versions --bare | grep '^3\.12\.' | tail -1)/bin/python3.12"
  fi
fi

# 3. Try system python3.12
if [[ -z "$PYTHON_BIN" ]] && command -v python3.12 &>/dev/null; then
  PYTHON_BIN="python3.12"
fi

# 4. Not found — install via Homebrew
if [[ -z "$PYTHON_BIN" ]]; then
  echo "==> Python 3.12 not found. Installing via Homebrew..."
  brew install python@3.12
  PYTHON_BIN="$(brew --prefix python@3.12)/bin/python3.12"
fi

echo "==> Using Python: $PYTHON_BIN ($($PYTHON_BIN --version))"

echo "==> Creating virtual environment at .venv ..."
"$PYTHON_BIN" -m venv .venv

echo "==> Activating .venv and installing dependencies..."
source .venv/bin/activate
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet

echo ""
echo "✅ Setup complete."
echo ""
echo "   To activate the environment in your current shell:"
echo "     source .venv/bin/activate"
echo ""
echo "   Then run the pipeline:"
echo "     dbt seed && dbt run && dbt test"
echo ""
echo "   Run a SPEC file:"
echo "     duckdb -c \"\$(cat specs/fact_orders/customer-running-total.spec.sql)\""
echo ""
echo "   Lint SQL:"
echo "     sqlfluff lint models/"
