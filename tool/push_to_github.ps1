# Upload this project to GitHub (one-time setup: gh auth login)
# Usage:
#   gh auth login
#   powershell -ExecutionPolicy Bypass -File tool\push_to_github.ps1

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$RepoName = "lnu_app_class_locator"

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    Write-Host "GitHub CLI (gh) is not installed. Install from https://cli.github.com/ or run:"
    Write-Host "  winget install GitHub.cli"
    exit 1
}

Push-Location $Root
try {
    gh auth status | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Log in to GitHub first:"
        Write-Host "  gh auth login"
        exit 1
    }

    $user = gh api user -q .login
    Write-Host "GitHub user: $user"
    Write-Host "Creating/updating remote and pushing to $RepoName ..."

    $remoteUrl = "https://github.com/${user}/${RepoName}.git"
    $hasOrigin = $false
    git remote get-url origin 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $hasOrigin = $true }

    if ($hasOrigin) {
        git remote set-url origin $remoteUrl
    } else {
        gh repo view "${user}/${RepoName}" 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            gh repo create $RepoName --public --source . --remote origin --description "LNU SmartPath class locator and e-slip schedule extractor"
        } else {
            git remote add origin $remoteUrl
        }
    }

    git push -u origin main
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host ('Done: https://github.com/' + $user + '/' + $RepoName)
    }
} finally {
    Pop-Location
}
