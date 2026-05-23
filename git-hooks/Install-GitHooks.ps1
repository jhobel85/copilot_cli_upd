# Install-GitHooks.ps1
# Installs git-autocommit-block to block commits unless GIT_HUMAN_APPROVED=1.
#
# Usage (from repo root):
#   .\git-hooks\Install-GitHooks.ps1            # install into THIS repo only
#   .\git-hooks\Install-GitHooks.ps1 -Global    # install globally (all repos on this machine)
#   .\git-hooks\Install-GitHooks.ps1 -Uninstall # remove (local or global, matches -Global flag)

param(
    [switch]$Global,
    [switch]$Uninstall
)

$sourceDir = $PSScriptRoot

# Resolve target hooks directory
if ($Global) {
    $hooksDir = Join-Path $HOME ".config\git\hooks"
} else {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $repoRoot) {
        Write-Error "Not inside a git repository. Run from within a repo or use -Global."
        exit 1
    }
    $hooksDir = Join-Path $repoRoot ".git\hooks"
}

if ($Uninstall) {
    if ($Global) {
        git config --global --unset core.hooksPath
        Write-Host "✅ Global core.hooksPath removed. Commits are now unprotected on all repos."
    } else {
        Remove-Item (Join-Path $hooksDir "git-autocommit-block") -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $hooksDir "pre-commit")           -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Hooks removed from: $hooksDir"
    }
    return
}

# Install
New-Item -ItemType Directory -Force $hooksDir | Out-Null
Copy-Item (Join-Path $sourceDir "git-autocommit-block") $hooksDir -Force
Copy-Item (Join-Path $sourceDir "pre-commit")           $hooksDir -Force

if ($Global) {
    git config --global core.hooksPath $hooksDir
    Write-Host "✅ git-autocommit-block installed globally at: $hooksDir"
    Write-Host "   Applies to ALL git repos on this machine."
} else {
    Write-Host "✅ git-autocommit-block installed locally at: $hooksDir"
    Write-Host "   Applies to THIS repo only."
}

Write-Host ""
Write-Host "To commit (PowerShell):"
Write-Host '  $env:GIT_HUMAN_APPROVED=1; git commit -m "your message"'
Write-Host ""
Write-Host "To bypass (use sparingly):"
Write-Host '  git commit --no-verify -m "your message"'
