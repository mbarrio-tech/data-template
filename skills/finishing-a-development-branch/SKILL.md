---
name: finishing-a-development-branch
description: Use when implementation is complete and all tests pass, to decide how to integrate the work — merge locally, open a PR, keep, or discard.
---

# Finishing a Development Branch

## Overview

Guide completion of development work by verifying tests pass, then presenting clear integration options.

**Core principle:** Verify tests → present options → execute choice → clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## Step 1: Verify Tests

Run the project's full test suite **before presenting any options**:

```bash
# Use whichever applies to this project
npm test / dotnet test / pytest / go test ./... / mvn test
```

**If tests fail:**
```
Tests failing (N failures). Must fix before completing:

[Show failures]

Cannot proceed with merge or PR until all tests pass.
```

Stop here. Do not proceed to Step 2.

**If tests pass:** continue.

## Step 2: Determine Base Branch

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

If unclear, ask: "This branch will merge back to main — is that correct?"

## Step 3: Present Options

Present exactly these 4 options:

```
Implementation complete. All tests pass. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and open a Pull Request
3. Keep the branch as-is (handle it later)
4. Discard this work

Which option?
```

Do not add explanation — keep the options concise.

## Step 4: Execute Choice

### Option 1: Merge Locally

```bash
git checkout <base-branch>
git pull
git merge <feature-branch>
<run test suite again>
git branch -d <feature-branch>
```

### Option 2: Push and Open a PR

```bash
git push -u origin <feature-branch>
```

Then create the PR with:
- **Title:** `[type]: <what this does>`
- **Body:**
  ```
  ## Summary
  [2–3 bullets of what changed]

  ## Polaris deliverable
  [Which deliverable from polaris.md this serves]

  ## Test plan
  [What was tested and how]

  ## Checklist
  - [ ] Tests pass
  - [ ] No secrets or credentials in code
  - [ ] Docs updated if behaviour changed
  ```

### Option 3: Keep Branch

No action needed. Confirm: "Branch `<name>` kept. You can integrate it later."

### Option 4: Discard

```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Confirm: "Branch `<name>` discarded. All commits on that branch are gone."

## Common Mistakes

- Presenting merge options before tests pass
- Merging without pulling latest from base branch first
- Opening a PR with a failing test suite
- Forgetting to delete the feature branch after a local merge
