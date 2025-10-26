# Fix App Service Configuration
$ResourceGroup = "ecommerce-full-rg"
$AppServiceName = "ecomm-app-4379"
$KeyVaultName = "ecomm-kv-4379"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FIXING APP SERVICE CONFIGURATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get Cosmos DB connection string from Key Vault
Write-Host "[1/4] Getting Cosmos DB connection from Key Vault..." -ForegroundColor Cyan
$mongoUri = az keyvault secret show --vault-name $KeyVaultName --name "MONGO-URI" --query value -o tsv
Write-Host "  [SUCCESS] Connection string retrieved!" -ForegroundColor Green

# Get Azure Storage connection string
Write-Host "[2/4] Getting Storage connection from Key Vault..." -ForegroundColor Cyan
$storageConn = az keyvault secret show --vault-name $KeyVaultName --name "AZURE-STORAGE-CONNECTION-STRING" --query value -o tsv
Write-Host "  [SUCCESS] Storage connection retrieved!" -ForegroundColor Green

# Set App Service configuration
Write-Host "[3/4] Configuring App Service..." -ForegroundColor Cyan
az webapp config appsettings set --name $AppServiceName --resource-group $ResourceGroup --settings `
    "MONGO_DBURL=$mongoUri" `
    "CLIENT_URL=https://$AppServiceName.azurewebsites.net" `
    "PORT=8080" `
    "NODE_ENV=production" `
    "AZURE_STORAGE_CONNECTION_STRING=$storageConn" `
    "KEY_VAULT_NAME=$KeyVaultName" `
    --output none

Write-Host "  [SUCCESS] Configuration updated!" -ForegroundColor Green

# Restart App Service
Write-Host "[4/4] Restarting App Service..." -ForegroundColor Cyan
az webapp restart --name $AppServiceName --resource-group $ResourceGroup
Write-Host "  [SUCCESS] App restarted!" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  CONFIGURATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Wait 30-60 seconds, then test:" -ForegroundColor Yellow
Write-Host "  curl https://$AppServiceName.azurewebsites.net/api/health" -ForegroundColor White
Write-Host ""
Write-Host "Your website: https://$AppServiceName.azurewebsites.net" -ForegroundColor Cyan
