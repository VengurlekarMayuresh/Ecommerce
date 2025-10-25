# Complete Setup and Deployment for Azure E-Commerce
# This script configures all services and deploys your application

$ResourceGroup = "ecommerce-full-rg"
$CosmosAccountName = "ecomm-cosmos-4379"
$KeyVaultName = "ecomm-kv-4379"
$StorageAccountName = "ecommstore4379"
$AppServiceName = "ecomm-app-4379"
$CommServiceName = "ecomm-comm-4379"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AZURE E-COMMERCE SETUP & DEPLOYMENT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Get all connection strings and URLs
Write-Host "[1/5] Gathering Azure service information..." -ForegroundColor Cyan

# Cosmos DB connection string
Write-Host "  Getting Cosmos DB connection..." -ForegroundColor Gray
$CosmosUri = az cosmosdb keys list `
    --name $CosmosAccountName `
    --resource-group $ResourceGroup `
    --type connection-strings `
    --query "connectionStrings[0].connectionString" -o tsv

# Storage account details
Write-Host "  Getting Storage account details..." -ForegroundColor Gray
$StorageConnectionString = az storage account show-connection-string `
    --name $StorageAccountName `
    --resource-group $ResourceGroup `
    --query connectionString -o tsv

$StorageKey = az storage account keys list `
    --account-name $StorageAccountName `
    --resource-group $ResourceGroup `
    --query "[0].value" -o tsv

$StorageBaseUrl = "https://$StorageAccountName.blob.core.windows.net"

# Communication Services
Write-Host "  Getting Communication Services connection..." -ForegroundColor Gray
$CommConnectionString = az communication list-key `
    --name $CommServiceName `
    --resource-group $ResourceGroup `
    --query primaryConnectionString -o tsv

# App Service URL
$WebAppUrl = "https://$AppServiceName.azurewebsites.net"

Write-Host "  [SUCCESS] All service information gathered!" -ForegroundColor Green
Write-Host ""

# Step 2: Get credentials from user
Write-Host "[2/5] Please provide your credentials..." -ForegroundColor Cyan
Write-Host ""

# PayPal
$PaypalClientId = Read-Host "PayPal Client ID"
$PaypalSecret = Read-Host "PayPal Client Secret"
$PaypalMode = Read-Host "PayPal Mode (sandbox/live)"

# JWT Secret
$JwtSecret = Read-Host "JWT Secret (or press Enter to use existing: MAYURESH_CCL)"
if ([string]::IsNullOrWhiteSpace($JwtSecret)) {
    $JwtSecret = "MAYURESH_CCL"
}

$AdminEmail = Read-Host "Admin Email (or press Enter for: onlinemayuresh29@gmail.com)"
if ([string]::IsNullOrWhiteSpace($AdminEmail)) {
    $AdminEmail = "onlinemayuresh29@gmail.com"
}

Write-Host ""

# Step 3: Update Key Vault secrets
Write-Host "[3/5] Updating Key Vault secrets..." -ForegroundColor Cyan

Write-Host "  Storing Cosmos DB connection..." -ForegroundColor Gray
az keyvault secret set --vault-name $KeyVaultName --name "MONGO-URI" --value "$CosmosUri" --output none

Write-Host "  Storing JWT secret..." -ForegroundColor Gray
az keyvault secret set --vault-name $KeyVaultName --name "JWT-SECRET" --value "$JwtSecret" --output none

Write-Host "  Storing Storage account credentials..." -ForegroundColor Gray
az keyvault secret set --vault-name $KeyVaultName --name "AZURE-STORAGE-CONNECTION-STRING" --value "$StorageConnectionString" --output none
az keyvault secret set --vault-name $KeyVaultName --name "AZURE-STORAGE-ACCOUNT-NAME" --value "$StorageAccountName" --output none
az keyvault secret set --vault-name $KeyVaultName --name "AZURE-STORAGE-ACCOUNT-KEY" --value "$StorageKey" --output none

Write-Host "  Storing Communication Services connection..." -ForegroundColor Gray
az keyvault secret set --vault-name $KeyVaultName --name "AZURE-COMMUNICATION-CONNECTION-STRING" --value "$CommConnectionString" --output none

Write-Host "  Storing PayPal credentials..." -ForegroundColor Gray
az keyvault secret set --vault-name $KeyVaultName --name "PAYPAL-CLIENT-ID" --value "$PaypalClientId" --output none
az keyvault secret set --vault-name $KeyVaultName --name "PAYPAL-CLIENT-SECRET" --value "$PaypalSecret" --output none
az keyvault secret set --vault-name $KeyVaultName --name "PAYPAL-MODE" --value "$PaypalMode" --output none

Write-Host "  Storing admin email..." -ForegroundColor Gray
az keyvault secret set --vault-name $KeyVaultName --name "ADMIN-EMAIL" --value "$AdminEmail" --output none

Write-Host "  [SUCCESS] All secrets stored in Key Vault!" -ForegroundColor Green
Write-Host ""

# Step 4: Configure App Service
Write-Host "[4/5] Configuring App Service..." -ForegroundColor Cyan

# Create settings array
$settings = @(
    "KEY_VAULT_NAME=$KeyVaultName"
    "MONGO_URI=@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/MONGO-URI/)"
    "SECRET_KEY=@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/JWT-SECRET/)"
    "AZURE_STORAGE_CONNECTION_STRING=@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/AZURE-STORAGE-CONNECTION-STRING/)"
    "AZURE_STORAGE_ACCOUNT_NAME=$StorageAccountName"
    "AZURE_STORAGE_ACCOUNT_KEY=@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/AZURE-STORAGE-ACCOUNT-KEY/)"
    "AZURE_STORAGE_BASE_URL=$StorageBaseUrl"
    "AZURE_COMMUNICATION_CONNECTION_STRING=@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/AZURE-COMMUNICATION-CONNECTION-STRING/)"
    "PAYPAL_CLIENT_ID=@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/PAYPAL-CLIENT-ID/)"
    "PAYPAL_CLIENT_SECRET=@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/PAYPAL-CLIENT-SECRET/)"
    "PAYPAL_MODE=$PaypalMode"
    "ADMIN_EMAIL=$AdminEmail"
    "NODE_ENV=production"
    "PORT=8080"
    "WEBSITE_NODE_DEFAULT_VERSION=~20"
    "SCM_DO_BUILD_DURING_DEPLOYMENT=true"
)

# Apply settings
foreach ($setting in $settings) {
    Write-Host "  Setting: $($setting.Split('=')[0])" -ForegroundColor Gray
}

az webapp config appsettings set `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --settings $settings `
    --output none

Write-Host "  [SUCCESS] App Service configured!" -ForegroundColor Green
Write-Host ""

# Step 5: Install Azure dependencies in backend
Write-Host "[5/5] Installing Azure SDK dependencies..." -ForegroundColor Cyan

Set-Location server

# Check if package.json exists
if (Test-Path "package.json") {
    Write-Host "  Installing Azure packages..." -ForegroundColor Gray
    npm install --save @azure/identity @azure/keyvault-secrets @azure/storage-blob @azure/communication-email
    
    Write-Host "  [SUCCESS] Dependencies installed!" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] server/package.json not found" -ForegroundColor Yellow
}

Set-Location ..

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  CONFIGURATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Save all URLs and configuration
$configInfo = @"
=====================================
AZURE E-COMMERCE - CONFIGURATION
=====================================

WEB APPLICATION:
----------------
Live URL: $WebAppUrl
App Service: $AppServiceName

AZURE SERVICES:
---------------
1. Cosmos DB (MongoDB):
   Account: $CosmosAccountName
   Connection: Stored in Key Vault
   
2. Blob Storage:
   Account: $StorageAccountName
   Base URL: $StorageBaseUrl
   Containers:
   - product-images: $StorageBaseUrl/product-images
   - user-uploads: $StorageBaseUrl/user-uploads

3. Key Vault:
   Name: $KeyVaultName
   URL: https://$KeyVaultName.vault.azure.net
   Secrets: All credentials stored securely

4. Communication Services:
   Name: $CommServiceName
   Status: Email domain needs provisioning

CONFIGURATION:
--------------
PayPal Mode: $PaypalMode
Admin Email: $AdminEmail
Environment: Production

NEXT STEPS:
-----------
1. Deploy your application:
   Run: .\deploy-website.ps1

2. Configure Email Domain (IMPORTANT):
   - Go to: https://portal.azure.com
   - Navigate to: Communication Services -> $CommServiceName
   - Click: Email -> Provision domains
   - Select: Azure Managed Domain (FREE)
   - Wait 5-10 minutes for provisioning
   - Copy sender email address
   - Update Key Vault secret:
     az keyvault secret set --vault-name $KeyVaultName --name "SENDER-EMAIL" --value "DoNotReply@..."

3. Monitor Application:
   az webapp log tail --name $AppServiceName --resource-group $ResourceGroup

4. View in Azure Portal:
   Resource Group: https://portal.azure.com/#@/resource/subscriptions/266f9e55-2ba1-43eb-9cc4-bf2944999382/resourceGroups/$ResourceGroup

IMPORTANT URLS:
---------------
Frontend: $WebAppUrl
API Base: $WebAppUrl/api
Storage: $StorageBaseUrl
Key Vault: https://$KeyVaultName.vault.azure.net
Azure Portal: https://portal.azure.com

"@

$configInfo | Out-File -FilePath "azure-config.txt" -Encoding UTF8

Write-Host "Configuration saved to: azure-config.txt" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  READY TO DEPLOY!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Run this command to deploy your website:" -ForegroundColor Yellow
Write-Host "  .\deploy-website.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Your live URL will be:" -ForegroundColor Yellow
Write-Host "  $WebAppUrl" -ForegroundColor White
Write-Host ""
