#!/usr/bin/env bash
# bootstrap-claude.sh
#
# Install project-template Claude Code configuration into a sibling project.
#
# Run this script from INSIDE project-template (or open project-template as
# the workspace and call /adopt — it will run this script for you).
#
# Usage:
#   ./bootstrap-claude.sh                  # interactive sibling picker
#   ./bootstrap-claude.sh my-project       # specify sibling by name
#
# Assumes: this script lives at <Repos>/project-template/bootstrap-claude.sh
# Siblings live at:              <Repos>/<project-name>/

set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOS_DIR="$(dirname "$TEMPLATE_DIR")"
TEMPLATE_NAME="$(basename "$TEMPLATE_DIR")"

# ── Colours ────────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ── Validate location ──────────────────────────────────────────────────────────
if [[ ! -f "$TEMPLATE_DIR/CLAUDE.md" ]]; then
  echo "Error: Could not locate CLAUDE.md. Run this script from the project-template root." >&2
  exit 1
fi

# ── Discover siblings ──────────────────────────────────────────────────────────
mapfile -t SIBLINGS < <(
  find "$REPOS_DIR" -mindepth 1 -maxdepth 1 -type d \
    ! -name "$TEMPLATE_NAME" \
    -exec basename {} \;
)

if [[ ${#SIBLINGS[@]} -eq 0 ]]; then
  echo "Error: No sibling project directories found in: $REPOS_DIR" >&2
  exit 1
fi

# ── Resolve target ─────────────────────────────────────────────────────────────
TARGET_ARG="${1:-}"

if [[ -z "$TARGET_ARG" ]]; then
  echo ""
  echo -e "${CYAN}Available sibling projects:${NC}"
  i=1
  for s in "${SIBLINGS[@]}"; do
    if [[ -f "$REPOS_DIR/$s/CLAUDE.md" ]]; then
      echo "  $i. $s (already has CLAUDE.md)"
    else
      echo "  $i. $s"
    fi
    ((i++))
  done
  echo ""
  read -r -p "Enter the number or name of the target project: " CHOICE

  if [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
    IDX=$(( CHOICE - 1 ))
    if (( IDX < 0 || IDX >= ${#SIBLINGS[@]} )); then
      echo "Error: Invalid selection." >&2
      exit 1
    fi
    TARGET_DIR="$REPOS_DIR/${SIBLINGS[$IDX]}"
  else
    TARGET_DIR="$REPOS_DIR/$CHOICE"
    if [[ ! -d "$TARGET_DIR" ]]; then
      echo "Error: No sibling project named '$CHOICE' found." >&2
      exit 1
    fi
  fi
else
  TARGET_DIR="$REPOS_DIR/$TARGET_ARG"
  if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Target project not found: $TARGET_DIR" >&2
    exit 1
  fi
fi

TARGET_NAME="$(basename "$TARGET_DIR")"

echo ""
echo -e "${CYAN}Bootstrap Claude Code configuration${NC}"
echo "  Template : $TEMPLATE_DIR"
echo "  Target   : $TARGET_DIR"
echo ""

# ── Helper ─────────────────────────────────────────────────────────────────────
copy_if_absent() {
  local src="$1"
  local dest="$2"
  local rel="${dest#$TARGET_DIR/}"

  if [[ -e "$dest" ]]; then
    echo -e "  ${YELLOW}SKIP  (exists)${NC} : $rel"
    return
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ -d "$src" ]]; then
    cp -r "$src" "$dest"
  else
    cp "$src" "$dest"
  fi
  echo -e "  ${GREEN}COPIED        ${NC} : $rel"
}

# ── Individual files ───────────────────────────────────────────────────────────
copy_if_absent "$TEMPLATE_DIR/.claude/settings.json"  "$TARGET_DIR/.claude/settings.json"
copy_if_absent "$TEMPLATE_DIR/hooks/hooks.json"        "$TARGET_DIR/hooks/hooks.json"
copy_if_absent "$TEMPLATE_DIR/hooks/session-start"     "$TARGET_DIR/hooks/session-start"
copy_if_absent "$TEMPLATE_DIR/hooks/session-start.ps1" "$TARGET_DIR/hooks/session-start.ps1"
copy_if_absent "$TEMPLATE_DIR/CLAUDE.md"               "$TARGET_DIR/CLAUDE.md"

# ── Directories ────────────────────────────────────────────────────────────────
for d in agents skills docs; do
  copy_if_absent "$TEMPLATE_DIR/$d" "$TARGET_DIR/$d"
done

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Done.${NC}"
echo ""
echo "Next steps:"
echo "  1. Open '$TARGET_NAME' as a workspace in Claude Code."
echo "  2. The session-start hook detects the CLAUDE.md placeholders automatically."
echo "  3. Claude will offer Flow B — the project-adoption wizard."
echo "     Answer its questions and it will populate docs/ with real project context."
echo ""
