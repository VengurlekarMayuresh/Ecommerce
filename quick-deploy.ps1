# Quick Deploy Script with Pre-flight Checks
# This script validates your environment before deployment

Write-Host "🚀 E-Commerce Azure Deployment - Pre-flight Checks" -ForegroundColor Cyan
Write-Host ""

# Check 1: Azure CLI
Write-Host "Checking Azure CLI..." -NoNewline
if (Get-Command az -ErrorAction SilentlyContinue) {
    $azVersion = (az version --output json | ConvertFrom-Json).'azure-cli'
    Write-Host " ✅ Installed (v$azVersion)" -ForegroundColor Green
} else {
    Write-Host " ❌ Not installed" -ForegroundColor Red
    Write-Host "Please install from: https://aka.ms/azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check 2: Git
Write-Host "Checking Git..." -NoNewline
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitVersion = git --version
    Write-Host " ✅ Installed ($gitVersion)" -ForegroundColor Green
} else {
    Write-Host " ❌ Not installed" -ForegroundColor Red
    Write-Host "Please install from: https://git-scm.com/" -ForegroundColor Yellow
    exit 1
}

# Check 3: Node.js
Write-Host "Checking Node.js..." -NoNewline
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVersion = node --version
    Write-Host " ✅ Installed ($nodeVersion)" -ForegroundColor Green
} else {
    Write-Host " ❌ Not installed" -ForegroundColor Red
    Write-Host "Please install from: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Check 4: Project structure
Write-Host "Checking project structure..." -NoNewline
$hasClient = Test-Path "client"
$hasServer = Test-Path "server"
if ($hasClient -and $hasServer) {
    Write-Host " ✅ Valid" -ForegroundColor Green
} else {
    Write-Host " ❌ Invalid" -ForegroundColor Red
    Write-Host "Missing client or server directory" -ForegroundColor Yellow
    exit 1
}

# Check 5: Azure login status
Write-Host "Checking Azure login..." -NoNewline
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host " ✅ Logged in as $($account.user.name)" -ForegroundColor Green
} catch {
    Write-Host " ❌ Not logged in" -ForegroundColor Red
    Write-Host "Running 'az login'..." -ForegroundColor Yellow
    az login
}

Write-Host ""
Write-Host "✅ All pre-flight checks passed!" -ForegroundColor Green
Write-Host ""

# Prompt to continue
$continue = Read-Host "Do you want to continue with deployment? (y/n)"
if ($continue -ne "y") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "📋 Gathering information..." -ForegroundColor Cyan
Write-Host ""

# Gather information
$resourceGroup = Read-Host "Enter resource group name or press Enter for default [ecommerce-rg]"
if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
    $resourceGroup = "ecommerce-rg"
}

$location = Read-Host "Enter Azure region or press Enter for default [eastus]"
if ([string]::IsNullOrWhiteSpace($location)) {
    $location = "eastus"
}

Write-Host ""
Write-Host "🚀 Starting deployment with:" -ForegroundColor Cyan
Write-Host "  Resource Group: $resourceGroup" -ForegroundColor White
Write-Host "  Location: $location" -ForegroundColor White
Write-Host ""

# Confirmation
$confirm = Read-Host 'Proceed with deployment? This will create Azure resources. (y/n)'
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🎯 Running full deployment script..." -ForegroundColor Cyan
Write-Host "⏱️  This will take approximately 20-30 minutes..." -ForegroundColor Yellow
Write-Host ""

# Run the full deployment script
.\deploy-azure-complete.ps1 -ResourceGroup $resourceGroup -Location $location

Write-Host ""
Write-Host "✅ Deployment script completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📚 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Follow DEPLOYMENT_STEPS.md for manual configurations" -ForegroundColor White
Write-Host "  2. Configure GitHub Actions (Phase 8)" -ForegroundColor White
Write-Host "  3. Test your deployment (Phase 10)" -ForegroundColor White
Write-Host ""
Write-Host "💡 Run 'Get-Content DEPLOYMENT_STEPS.md' to view the guide" -ForegroundColor Yellow
