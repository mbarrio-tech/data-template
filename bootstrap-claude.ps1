<#
.SYNOPSIS
    Installs project-template Claude Code configuration into a sibling project.

.DESCRIPTION
    Run this script from INSIDE project-template (or open project-template as
    the workspace and call the /adopt agent — it will run this script for you).

    The script copies hooks, agents, skills, docs skeleton, and Claude Code
    settings from project-template into a sibling directory one level up.
    It never overwrites files that already exist in the target.

    On the next Claude Code session in the target project, the session-start hook
    will detect the unbootstrapped CLAUDE.md and offer Flow B automatically.

.PARAMETER Target
    Name of the sibling project directory (just the folder name, not a full path).
    If omitted, the script lists available siblings and asks you to choose.

.EXAMPLE
    # From inside project-template — interactive picker:
    .\bootstrap-claude.ps1

    # From inside project-template — specify the sibling directly:
    .\bootstrap-claude.ps1 -Target my-existing-project

.NOTES
    Assumes this script lives at: <Repos>/project-template/bootstrap-claude.ps1
    The sibling projects live at:  <Repos>/<project-name>/
#>
param(
    [string]$Target = ""
)

$ErrorActionPreference = "Stop"

# The template IS this repo — the script lives at its root.
$templateDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$reposDir    = Split-Path -Parent $templateDir

# ── Validate template location ────────────────────────────────────────────────
if (-not (Test-Path (Join-Path $templateDir "CLAUDE.md"))) {
    Write-Error "Could not locate CLAUDE.md. Run this script from the project-template root."
    exit 1
}

# ── Discover sibling projects ─────────────────────────────────────────────────
$siblings = Get-ChildItem -Path $reposDir -Directory |
    Where-Object { $_.Name -ne (Split-Path -Leaf $templateDir) }

if ($siblings.Count -eq 0) {
    Write-Error "No sibling project directories found in: $reposDir"
    exit 1
}

# ── Resolve target ────────────────────────────────────────────────────────────
if ($Target -eq "") {
    Write-Host ""
    Write-Host "Available sibling projects:" -ForegroundColor Cyan
    $i = 1
    foreach ($s in $siblings) {
        $adopted = Test-Path (Join-Path $s.FullName "CLAUDE.md")
        $status  = if ($adopted) { "(already has CLAUDE.md)" } else { "" }
        Write-Host "  $i. $($s.Name) $status"
        $i++
    }
    Write-Host ""
    $choice = Read-Host "Enter the number or name of the target project"

    if ($choice -match '^\d+$') {
        $idx = [int]$choice - 1
        if ($idx -lt 0 -or $idx -ge $siblings.Count) {
            Write-Error "Invalid selection."
            exit 1
        }
        $targetDir = $siblings[$idx].FullName
    }
    else {
        $match = $siblings | Where-Object { $_.Name -eq $choice }
        if (-not $match) {
            Write-Error "No sibling project named '$choice' found."
            exit 1
        }
        $targetDir = $match.FullName
    }
}
else {
    $targetDir = Join-Path $reposDir $Target
    if (-not (Test-Path $targetDir -PathType Container)) {
        Write-Error "Target project not found: $targetDir"
        exit 1
    }
}

Write-Host ""
Write-Host "Bootstrap Claude Code configuration" -ForegroundColor Cyan
Write-Host "  Template : $templateDir"
Write-Host "  Target   : $targetDir"
Write-Host ""

# ── Helper ────────────────────────────────────────────────────────────────────
function Copy-IfAbsent {
    param([string]$Src, [string]$Dest)

    if (Test-Path $Dest) {
        Write-Host "  SKIP  (exists) : $($Dest.Replace($targetDir, '').TrimStart('\/'))"
        return
    }

    $parent = Split-Path -Parent $Dest
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Test-Path $Src -PathType Container) {
        Copy-Item -Path $Src -Destination $Dest -Recurse -Force
    }
    else {
        Copy-Item -Path $Src -Destination $Dest -Force
    }
    Write-Host "  COPIED         : $($Dest.Replace($targetDir, '').TrimStart('\/'))"
}

# ── Individual files ──────────────────────────────────────────────────────────
$files = @(
    @{ Src = ".claude\settings.json";         Dest = ".claude\settings.json" }
    @{ Src = "hooks\hooks.json";              Dest = "hooks\hooks.json" }
    @{ Src = "hooks\session-start";           Dest = "hooks\session-start" }
    @{ Src = "hooks\session-start.ps1";       Dest = "hooks\session-start.ps1" }
    @{ Src = "CLAUDE.md";                     Dest = "CLAUDE.md" }
)

foreach ($f in $files) {
    Copy-IfAbsent `
        -Src  (Join-Path $templateDir $f.Src) `
        -Dest (Join-Path $targetDir   $f.Dest)
}

# ── Directories (agents, skills, docs) ───────────────────────────────────────
$dirs = @("agents", "skills", "docs")

foreach ($d in $dirs) {
    Copy-IfAbsent `
        -Src  (Join-Path $templateDir $d) `
        -Dest (Join-Path $targetDir   $d)
}

# ── Summary ───────────────────────────────────────────────────────────────────
$targetName = Split-Path -Leaf $targetDir
Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open '$targetName' as a workspace in Claude Code."
Write-Host "  2. The session-start hook detects the CLAUDE.md placeholders automatically."
Write-Host "  3. Claude will offer Flow B — the project-adoption wizard."
Write-Host "     Answer its questions and it will populate docs/ with real project context."
Write-Host ""
