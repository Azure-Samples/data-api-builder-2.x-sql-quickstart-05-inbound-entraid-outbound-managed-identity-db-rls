# Tear down this quickstart's Azure resources
# Usage: .\aspire-down.ps1 [-NoPurge]
# By default, resources are purged (soft-delete removed). Pass -NoPurge to keep them recoverable.

Param(
    [switch]$NoPurge
)

$ErrorActionPreference = "Stop"

Push-Location (Join-Path $PSScriptRoot "..")
try {
    az account show --only-show-errors 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Logging in to Azure CLI..." -ForegroundColor Yellow
        az login
        if ($LASTEXITCODE -ne 0) { throw "az login failed" }
    }

    if ($NoPurge) {
        azd down --force
    }
    else {
        azd down --force --purge
    }
    if ($LASTEXITCODE -ne 0) { throw "azd down failed" }
}
finally {
    Pop-Location
}
