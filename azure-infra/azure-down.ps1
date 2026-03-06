# Tear down this quickstart's Azure resources
# Usage: .\azure-down.ps1 [-NoPurge]
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

    # Clean up Entra ID resources (app registration, test user, config resets)
    $entraDown = Join-Path $PSScriptRoot "entra-down.ps1"
    if (Test-Path $entraDown) {
        Write-Host "Running Entra teardown..." -ForegroundColor Yellow
        & $entraDown
    }

    $quickstartRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $repoRoot = (Resolve-Path (Join-Path $quickstartRoot "..")).Path
    $mcpConfigPath = Join-Path $repoRoot ".github\mcp.json"

    if (Test-Path $mcpConfigPath) {
        $mcpRaw = Get-Content $mcpConfigPath -Raw
        if (-not [string]::IsNullOrWhiteSpace($mcpRaw)) {
            $mcpConfig = $mcpRaw | ConvertFrom-Json -AsHashtable
            if ($mcpConfig -and $mcpConfig.ContainsKey('servers') -and ($mcpConfig['servers'] -is [hashtable])) {
                if ($mcpConfig['servers'].ContainsKey('azure-sql-mcp-qs5')) {
                    $null = $mcpConfig['servers'].Remove('azure-sql-mcp-qs5')
                    $mcpConfig | ConvertTo-Json -Depth 100 | Out-File -FilePath $mcpConfigPath -Encoding utf8 -Force
                    Write-Host "Removed azure-sql-mcp-qs5 from .github/mcp.json" -ForegroundColor Green
                }
            }
        }
    }
}
finally {
    Pop-Location
}
