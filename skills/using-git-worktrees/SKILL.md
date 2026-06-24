---
name: using-git-worktrees
description: Use when starting feature work that needs branch isolation, or before executing implementation plans — creates isolated git worktrees so multiple branches can be worked simultaneously.
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces that share the same repository, allowing multiple branches to be worked simultaneously without switching back and forth.

**Core principle:** One worktree per feature branch. Never commit worktree directories to the repo.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 1: Choose a Worktree Directory

Check in this order:

```bash
# 1. Does a worktrees or .worktrees directory already exist?
ls -d .worktrees 2>/dev/null || ls -d worktrees 2>/dev/null
```

- If `.worktrees/` exists — use it (preferred, hidden from directory listings)
- If `worktrees/` exists — use it
- If neither exists — ask:

```
No worktree directory found. Where should worktrees be created?

1. .worktrees/ (project-local, hidden)
2. A directory outside the repo (no .gitignore concerns)

Which would you prefer?
```

## Step 2: Verify the Directory Is Git-Ignored

**BEFORE creating a worktree in a project-local directory, verify it is ignored:**

```bash
git check-ignore -q .worktrees 2>/dev/null && echo "ignored" || echo "NOT ignored"
```

**If NOT ignored:**

1. Add `.worktrees/` to `.gitignore`
2. Commit: `chore: ignore worktrees directory`
3. Then proceed

**Why this matters:** Accidentally committing worktree contents pollutes the repo history permanently.

## Step 3: Create the Worktree

```bash
# Detect project name for the worktree folder name
project=$(basename "$(git rev-parse --show-toplevel)")

# Create a new branch and worktree in one command
git worktree add .worktrees/${project}-<feature-name> -b <feature-branch-name>

# Or create a worktree for an existing branch
git worktree add .worktrees/${project}-<feature-name> <existing-branch>
```

## Step 4: Verify the Worktree

```bash
git worktree list
```

Confirm the new worktree appears with the correct branch.

## Step 5: Work in the Worktree

Open the worktree directory in your editor or navigate to it:

```bash
cd .worktrees/${project}-<feature-name>
```

The worktree is a full checkout — all your tools, test runners, and AI tools work normally inside it.

## Cleaning Up

After work is merged or discarded:

```bash
# Remove the worktree
git worktree remove .worktrees/${project}-<feature-name>

# If the branch was merged, delete it
git branch -d <feature-branch-name>

# Prune stale worktree references
git worktree prune
```

## Common Mistakes

- Creating the worktree directory without checking `.gitignore` first
- Working in the main checkout instead of the worktree (changes bleed between features)
- Forgetting to prune after removing — stale references accumulate
- Creating worktrees outside the repo when `.worktrees/` would be fine (makes navigation harder)
