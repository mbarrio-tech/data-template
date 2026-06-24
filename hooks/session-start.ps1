# hooks/session-start.ps1
# Windows (PowerShell) version of hooks/session-start.
# Fires on: SessionStart (new session, /clear, /compact — NOT on /resume).
#
# Detects whether the current project has been bootstrapped:
#   - If CLAUDE.md still contains [Project Name] → offer Flow A or Flow B
#   - Otherwise → inject live git context (branch, dirty files, last commit)
#
# Companion to: hooks/session-start  (bash version for Linux / macOS / WSL)
#
# Output format required by Claude Code hooks:
#   {"continue":true,"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<message>"}}

$ErrorActionPreference = "SilentlyContinue"

$claudeMd    = Join-Path (Get-Location) "CLAUDE.md"
$bootstrapped = $true

if ((Test-Path $claudeMd) -and ((Get-Content $claudeMd -Raw) -match '\[Project Name\]')) {
    $bootstrapped = $false
}

if (-not $bootstrapped) {
    $msg = "SETUP REQUIRED — This project has not been bootstrapped yet. CLAUDE.md still contains template placeholder text. Before doing anything else, tell the user: This project-template has not been set up yet. Ask them which flow they want: Flow A for a new project from scratch (run the inception agent) or Flow B to adopt the template into an existing project (run the project-adoption agent). Wait for their answer, then run the corresponding agent."
    $escaped = $msg -replace '"', '\"'
    Write-Output "{`"continue`":true,`"hookSpecificOutput`":{`"hookEventName`":`"SessionStart`",`"additionalContext`":`"$escaped`"}}"
    exit 0
}

# ── Bootstrapped: inject live git context ─────────────────────────────────────
$branch     = git rev-parse --abbrev-ref HEAD 2>$null
$dirty      = (git status --porcelain 2>$null | Measure-Object -Line).Lines
$lastCommit = git log -1 --format="%h %s" 2>$null

if (-not $branch)     { $branch     = "unknown" }
if (-not $lastCommit) { $lastCommit = "none" }

$msg     = "Current branch: $branch. Uncommitted changes: $dirty file(s). Last commit: $lastCommit."
$escaped = $msg -replace '"', '\"'
Write-Output "{`"continue`":true,`"hookSpecificOutput`":{`"hookEventName`":`"SessionStart`",`"additionalContext`":`"$escaped`"}}"
