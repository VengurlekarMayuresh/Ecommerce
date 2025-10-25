# Deployment Verification Script
# Run this after deployment to verify everything is working

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [string]$FrontendUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$BackendUrl
)

Write-Host "🔍 Verifying Azure Deployment" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$failed = 0

# Helper function for checks
function Test-Resource {
    param($Name, $ScriptBlock)
    Write-Host "Checking $Name..." -NoNewline
    try {
        $result = & $ScriptBlock
        if ($result) {
            Write-Host " ✅ OK" -ForegroundColor Green
            return $true
        } else {
            Write-Host " ❌ FAIL" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host " ❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Write-Host "📦 Checking Azure Resources..." -ForegroundColor Yellow
Write-Host ""

# Check Resource Group
if (Test-Resource "Resource Group" { az group show --name $ResourceGroup --output none; $? }) { $passed++ } else { $failed++ }

# Get resource names
$resources = az resource list --resource-group $ResourceGroup --output json | ConvertFrom-Json

# Check Cosmos DB
$cosmosDb = $resources | Where-Object { $_.type -eq "Microsoft.DocumentDB/databaseAccounts" }
if (Test-Resource "Cosmos DB" { $cosmosDb -ne $null }) { $passed++ } else { $failed++ }

# Check Key Vault
$keyVault = $resources | Where-Object { $_.type -eq "Microsoft.KeyVault/vaults" }
if (Test-Resource "Key Vault" { $keyVault -ne $null }) { $passed++ } else { $failed++ }

# Check Storage Account
$storage = $resources | Where-Object { $_.type -eq "Microsoft.Storage/storageAccounts" }
if (Test-Resource "Storage Account" { $storage -ne $null }) { $passed++ } else { $failed++ }

# Check App Service
$appService = $resources | Where-Object { $_.type -eq "Microsoft.Web/sites" -and $_.kind -like "*app*" }
if (Test-Resource "App Service" { $appService -ne $null }) { $passed++ } else { $failed++ }

# Check Static Web App
$staticWebApp = $resources | Where-Object { $_.type -eq "Microsoft.Web/staticSites" }
if (Test-Resource "Static Web App" { $staticWebApp -ne $null }) { $passed++ } else { $failed++ }

# Check Application Insights
$appInsights = $resources | Where-Object { $_.type -eq "microsoft.insights/components" }
if (Test-Resource "Application Insights" { $appInsights -ne $null }) { $passed++ } else { $failed++ }

# Check Communication Services
$commService = $resources | Where-Object { $_.type -eq "Microsoft.Communication/communicationServices" }
if (Test-Resource "Communication Services" { $commService -ne $null }) { $passed++ } else { $failed++ }

# Check Notification Hub
$notificationHub = $resources | Where-Object { $_.type -eq "Microsoft.NotificationHubs/namespaces" }
if (Test-Resource "Notification Hub" { $notificationHub -ne $null }) { $passed++ } else { $failed++ }

Write-Host ""
Write-Host "🌐 Checking Endpoints..." -ForegroundColor Yellow
Write-Host ""

# Get URLs if not provided
if ([string]::IsNullOrWhiteSpace($BackendUrl) -and $appService) {
    $BackendUrl = "https://$($appService.name).azurewebsites.net"
}

if ([string]::IsNullOrWhiteSpace($FrontendUrl) -and $staticWebApp) {
    $swaDetails = az staticwebapp show --name $staticWebApp.name --resource-group $ResourceGroup --output json | ConvertFrom-Json
    $FrontendUrl = "https://$($swaDetails.defaultHostname)"
}

# Check Backend
if ($BackendUrl) {
    Write-Host "Testing Backend API ($BackendUrl)..." -NoNewline
    try {
        $response = Invoke-WebRequest -Uri "$BackendUrl/api/health" -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host " ✅ OK" -ForegroundColor Green
            $passed++
        } else {
            Write-Host " ⚠️ Status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        # Try alternate endpoint if health doesn't exist
        try {
            $response = Invoke-WebRequest -Uri "$BackendUrl/api/products" -TimeoutSec 10 -ErrorAction Stop
            Write-Host " ✅ OK (via /api/products)" -ForegroundColor Green
            $passed++
        } catch {
            Write-Host " ❌ Not responding" -ForegroundColor Red
            $failed++
        }
    }
}

# Check Frontend
if ($FrontendUrl) {
    Write-Host "Testing Frontend ($FrontendUrl)..." -NoNewline
    try {
        $response = Invoke-WebRequest -Uri $FrontendUrl -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host " ✅ OK" -ForegroundColor Green
            $passed++
        } else {
            Write-Host " ⚠️ Status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host " ❌ Not responding" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "📊 Verification Summary" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host ""

if ($failed -eq 0) {
    Write-Host "✅ All checks passed! Your deployment is healthy." -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Your Application URLs:" -ForegroundColor Cyan
    if ($FrontendUrl) { Write-Host "Frontend: $FrontendUrl" -ForegroundColor White }
    if ($BackendUrl) { Write-Host "Backend:  $BackendUrl" -ForegroundColor White }
} else {
    Write-Host "⚠️ Some checks failed. Please review the errors above." -ForegroundColor Yellow
    Write-Host "Run 'az webapp log tail --name <app-name> --resource-group $ResourceGroup' to view logs" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Configure GitHub Actions (see DEPLOYMENT_STEPS.md Phase 8)" -ForegroundColor White
Write-Host "  2. Test full application flow (see DEPLOYMENT_STEPS.md Phase 10)" -ForegroundColor White
Write-Host "  3. Configure custom domain (optional, see DEPLOYMENT_STEPS.md Phase 12)" -ForegroundColor White
