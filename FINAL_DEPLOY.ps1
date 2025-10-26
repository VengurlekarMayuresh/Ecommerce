# FINAL DEPLOYMENT SCRIPT FOR E-COMMERCE TO AZURE
# This script will create a clean deployment package and deploy to Azure

$ResourceGroup = "ecommerce-full-rg"
$AppServiceName = "ecomm-app-4379"
$KeyVaultName = "ecomm-kv-4379"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FINAL E-COMMERCE DEPLOYMENT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify environment variables are set in Azure
Write-Host "[1/5] Verifying Azure configuration..." -ForegroundColor Cyan
$mongoUri = az webapp config appsettings list --name $AppServiceName --resource-group $ResourceGroup --query "[?name=='MONGO_DBURL'].value" -o tsv
$port = az webapp config appsettings list --name $AppServiceName --resource-group $ResourceGroup --query "[?name=='PORT'].value" -o tsv

if (-not $mongoUri) {
    Write-Host "  [ERROR] MONGO_DBURL not configured!" -ForegroundColor Red
    Write-Host "  Please configure environment variables first" -ForegroundColor Yellow
    exit 1
}

Write-Host "  [SUCCESS] Environment variables verified!" -ForegroundColor Green
Write-Host "    - MONGO_DBURL: Set" -ForegroundColor Gray
Write-Host "    - PORT: $port" -ForegroundColor Gray

# Step 2: Clean up old deployment files
Write-Host "[2/5] Cleaning up old deployments..." -ForegroundColor Cyan
if (Test-Path "server-deploy") {
    Remove-Item "server-deploy" -Recurse -Force
}
if (Test-Path "server-final.zip") {
    Remove-Item "server-final.zip" -Force
}
Write-Host "  [SUCCESS] Cleaned up!" -ForegroundColor Green

# Step 3: Create deployment package
Write-Host "[3/5] Creating deployment package..." -ForegroundColor Cyan
Copy-Item -Path "server" -Destination "server-deploy" -Recurse
Remove-Item "server-deploy/.env" -Force -ErrorAction SilentlyContinue
Remove-Item "server-deploy/node_modules" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "server-deploy/*.log" -Force -ErrorAction SilentlyContinue

# Create .deployment file for Azure
@"
[config]
SCM_DO_BUILD_DURING_DEPLOYMENT=true
"@ | Out-File -FilePath "server-deploy/.deployment" -Encoding ASCII

Write-Host "  [SUCCESS] Package prepared!" -ForegroundColor Green

# Step 4: Create ZIP
Write-Host "[4/5] Creating ZIP archive..." -ForegroundColor Cyan
Set-Location server-deploy
Compress-Archive -Path * -DestinationPath ../server-final.zip -Force
Set-Location ..
Write-Host "  [SUCCESS] ZIP created: server-final.zip" -ForegroundColor Green

# Step 5: Deploy to Azure
Write-Host "[5/5] Deploying to Azure..." -ForegroundColor Cyan
Write-Host "  This will take 2-5 minutes..." -ForegroundColor Yellow

az webapp deploy `
    --resource-group $ResourceGroup `
    --name $AppServiceName `
    --src-path "server-final.zip" `
    --type zip `
    --async true

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT INITIATED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Deployment is in progress..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Your website: https://$AppServiceName.azurewebsites.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "Wait 3-5 minutes, then test:" -ForegroundColor Yellow
Write-Host "  curl https://$AppServiceName.azurewebsites.net/api/health" -ForegroundColor White
Write-Host ""
Write-Host "Monitor deployment:" -ForegroundColor Yellow
Write-Host "  az webapp log tail --name $AppServiceName --resource-group $ResourceGroup" -ForegroundColor Gray
Write-Host ""
Write-Host "Check in Azure Portal:" -ForegroundColor Yellow
Write-Host "  https://portal.azure.com" -ForegroundColor Gray
Write-Host ""

# Clean up
Write-Host "Cleaning up temporary files..." -ForegroundColor Gray
Remove-Item "server-deploy" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "server-final.zip" -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[SUCCESS] Deployment complete!" -ForegroundColor Green
Write-Host ""
