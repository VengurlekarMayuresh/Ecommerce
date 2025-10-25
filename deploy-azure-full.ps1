# Full Azure Cloud-Native E-Commerce Deployment
# Uses: Cosmos DB, Blob Storage, Communication Services, Key Vault, App Insights

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "ecommerce-full-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastasia"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FULL AZURE E-COMMERCE DEPLOYMENT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Using Azure Services:" -ForegroundColor Yellow
Write-Host "  - Cosmos DB (MongoDB API)" -ForegroundColor White
Write-Host "  - Blob Storage (Images)" -ForegroundColor White
Write-Host "  - Communication Services (Email)" -ForegroundColor White
Write-Host "  - Key Vault (Secrets)" -ForegroundColor White
Write-Host "  - Application Insights (Monitoring)" -ForegroundColor White
Write-Host "  - App Service (Hosting)" -ForegroundColor White
Write-Host ""

# Generate unique suffix
$Suffix = Get-Random -Maximum 9999
$CosmosAccountName = "ecomm-cosmos-$Suffix"
$KeyVaultName = "ecomm-kv-$Suffix"
$StorageAccountName = "ecommstore$Suffix"
$AppServicePlan = "ecomm-plan-$Suffix"
$AppServiceName = "ecomm-app-$Suffix"
$AppInsightsName = "ecomm-insights-$Suffix"
$CommServiceName = "ecomm-comm-$Suffix"

Write-Host "Resource Names:" -ForegroundColor Yellow
Write-Host "  Cosmos DB: $CosmosAccountName"
Write-Host "  Key Vault: $KeyVaultName"
Write-Host "  Storage: $StorageAccountName"
Write-Host "  App Service: $AppServiceName"
Write-Host "  Communication: $CommServiceName"
Write-Host "  Location: $Location"
Write-Host ""

# 1. Create Resource Group
Write-Host "[1/7] Creating Resource Group..." -ForegroundColor Cyan
az group create --name $ResourceGroup --location $Location

# 2. Create Cosmos DB (MongoDB API)
Write-Host "[2/7] Creating Cosmos DB with MongoDB API..." -ForegroundColor Cyan
Write-Host "  (This takes 5-10 minutes - please wait)" -ForegroundColor Yellow

az cosmosdb create `
    --name $CosmosAccountName `
    --resource-group $ResourceGroup `
    --kind MongoDB `
    --server-version 4.2 `
    --default-consistency-level Session `
    --locations regionName=$Location failoverPriority=0 `
    --enable-free-tier true

# Get Cosmos DB connection string
$CosmosConnectionString = az cosmosdb keys list `
    --name $CosmosAccountName `
    --resource-group $ResourceGroup `
    --type connection-strings `
    --query "connectionStrings[0].connectionString" -o tsv

Write-Host "  [SUCCESS] Cosmos DB created!" -ForegroundColor Green

# 3. Create Storage Account (for images)
Write-Host "[3/7] Creating Blob Storage..." -ForegroundColor Cyan

az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --allow-blob-public-access true

# Create containers
az storage container create `
    --name product-images `
    --account-name $StorageAccountName `
    --public-access blob

az storage container create `
    --name user-uploads `
    --account-name $StorageAccountName `
    --public-access blob

# Get storage connection string
$StorageConnectionString = az storage account show-connection-string `
    --name $StorageAccountName `
    --resource-group $ResourceGroup `
    --query connectionString -o tsv

$StorageKey = az storage account keys list `
    --account-name $StorageAccountName `
    --resource-group $ResourceGroup `
    --query "[0].value" -o tsv

Write-Host "  [SUCCESS] Blob Storage created!" -ForegroundColor Green

# 4. Create Key Vault
Write-Host "[4/7] Creating Key Vault..." -ForegroundColor Cyan

# Register provider if needed
az provider register --namespace Microsoft.KeyVault --wait

az keyvault create `
    --name $KeyVaultName `
    --resource-group $ResourceGroup `
    --location $Location `
    --enable-rbac-authorization false

Write-Host "  [SUCCESS] Key Vault created!" -ForegroundColor Green

# 5. Create Communication Services
Write-Host "[5/7] Creating Communication Services (Email)..." -ForegroundColor Cyan

az communication create `
    --name $CommServiceName `
    --resource-group $ResourceGroup `
    --location "global" `
    --data-location "United States"

$CommConnectionString = az communication list-key `
    --name $CommServiceName `
    --resource-group $ResourceGroup `
    --query primaryConnectionString -o tsv

Write-Host "  [SUCCESS] Communication Services created!" -ForegroundColor Green
Write-Host "  [NOTE] You need to provision email domain in Azure Portal later" -ForegroundColor Yellow

# 6. Create Application Insights
Write-Host "[6/7] Creating Application Insights..." -ForegroundColor Cyan

# Register provider if needed
az provider register --namespace microsoft.insights --wait

az monitor app-insights component create `
    --app $AppInsightsName `
    --location $Location `
    --resource-group $ResourceGroup `
    --application-type web

$AppInsightsKey = az monitor app-insights component show `
    --app $AppInsightsName `
    --resource-group $ResourceGroup `
    --query instrumentationKey -o tsv

$AppInsightsConnectionString = az monitor app-insights component show `
    --app $AppInsightsName `
    --resource-group $ResourceGroup `
    --query connectionString -o tsv

Write-Host "  [SUCCESS] Application Insights created!" -ForegroundColor Green

# 7. Create App Service
Write-Host "[7/7] Creating App Service..." -ForegroundColor Cyan

# Create App Service Plan (Free tier)
az appservice plan create `
    --name $AppServicePlan `
    --resource-group $ResourceGroup `
    --location $Location `
    --is-linux `
    --sku B1

# Get Node runtime
$nodeRuntime = "NODE:20-lts"

# Create Web App
az webapp create `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --plan $AppServicePlan `
    --runtime $nodeRuntime

# Enable managed identity
az webapp identity assign `
    --name $AppServiceName `
    --resource-group $ResourceGroup

$PrincipalId = az webapp identity show `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --query principalId -o tsv

# Grant Key Vault access to App Service
az keyvault set-policy `
    --name $KeyVaultName `
    --object-id $PrincipalId `
    --secret-permissions get list

Write-Host "  [SUCCESS] App Service created!" -ForegroundColor Green
Write-Host ""

# Get user credentials
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PROVIDE YOUR CREDENTIALS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# JWT Secret
$JwtSecret = Read-Host "JWT Secret (or press Enter to auto-generate)"
if ([string]::IsNullOrWhiteSpace($JwtSecret)) {
    $JwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    Write-Host "[*] Generated JWT Secret: $JwtSecret" -ForegroundColor Green
}

# PayPal
$PaypalClientId = Read-Host "PayPal Client ID"
$PaypalSecret = Read-Host "PayPal Client Secret (input hidden)" -AsSecureString
$PaypalSecretText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PaypalSecret))
$PaypalMode = Read-Host "PayPal Mode (sandbox/live)"

# Admin email for notifications
$AdminEmail = Read-Host "Admin Email (for order notifications)"

Write-Host ""
Write-Host "[*] Storing secrets in Key Vault..." -ForegroundColor Cyan

# Store secrets in Key Vault
az keyvault secret set --vault-name $KeyVaultName --name "MONGO-URI" --value $CosmosConnectionString | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "JWT-SECRET" --value $JwtSecret | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "AZURE-STORAGE-CONNECTION-STRING" --value $StorageConnectionString | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "AZURE-STORAGE-ACCOUNT-NAME" --value $StorageAccountName | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "AZURE-STORAGE-ACCOUNT-KEY" --value $StorageKey | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "AZURE-COMMUNICATION-CONNECTION-STRING" --value $CommConnectionString | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "PAYPAL-CLIENT-ID" --value $PaypalClientId | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "PAYPAL-CLIENT-SECRET" --value $PaypalSecretText | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "PAYPAL-MODE" --value $PaypalMode | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "ADMIN-EMAIL" --value $AdminEmail | Out-Null

Write-Host "  [SUCCESS] All secrets stored!" -ForegroundColor Green
Write-Host ""

# Configure App Service
Write-Host "[*] Configuring App Service..." -ForegroundColor Cyan

$webAppUrl = "https://$AppServiceName.azurewebsites.net"
$storageBaseUrl = "https://$StorageAccountName.blob.core.windows.net"

az webapp config appsettings set `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --settings `
        KEY_VAULT_NAME=$KeyVaultName `
        MONGO_URI="@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/MONGO-URI/)" `
        SECRET_KEY="@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/JWT-SECRET/)" `
        AZURE_STORAGE_CONNECTION_STRING="@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/AZURE-STORAGE-CONNECTION-STRING/)" `
        AZURE_STORAGE_ACCOUNT_NAME=$StorageAccountName `
        AZURE_STORAGE_ACCOUNT_KEY="@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/AZURE-STORAGE-ACCOUNT-KEY/)" `
        AZURE_STORAGE_BASE_URL=$storageBaseUrl `
        AZURE_COMMUNICATION_CONNECTION_STRING="@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/AZURE-COMMUNICATION-CONNECTION-STRING/)" `
        PAYPAL_CLIENT_ID="@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/PAYPAL-CLIENT-ID/)" `
        PAYPAL_CLIENT_SECRET="@Microsoft.KeyVault(SecretUri=https://$KeyVaultName.vault.azure.net/secrets/PAYPAL-CLIENT-SECRET/)" `
        PAYPAL_MODE=$PaypalMode `
        ADMIN_EMAIL=$AdminEmail `
        NODE_ENV=production `
        PORT=8080 `
        WEBSITE_NODE_DEFAULT_VERSION="~20" `
        APPLICATIONINSIGHTS_CONNECTION_STRING=$AppInsightsConnectionString `
        SCM_DO_BUILD_DURING_DEPLOYMENT=true

# Enable logging
az webapp log config `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --application-logging filesystem `
    --detailed-error-messages true `
    --failed-request-tracing true `
    --web-server-logging filesystem

Write-Host "  [SUCCESS] App Service configured!" -ForegroundColor Green
Write-Host ""

# Download publish profile
az webapp deployment list-publishing-profiles `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --xml > azure-publish-profile.xml

# Save deployment information
$deploymentInfo = @"
=====================================
AZURE FULL DEPLOYMENT - COMPLETE!
=====================================

WEB APP URL: $webAppUrl
Resource Group: $ResourceGroup
Location: $Location

AZURE SERVICES:
---------------
1. Cosmos DB (MongoDB): $CosmosAccountName
   Connection stored in Key Vault

2. Blob Storage: $StorageAccountName
   Base URL: $storageBaseUrl
   Containers: product-images, user-uploads

3. Key Vault: $KeyVaultName
   All secrets securely stored

4. Communication Services: $CommServiceName
   NOTE: Configure email domain in Azure Portal:
   portal.azure.com -> Communication Services -> Email -> Provision domains

5. Application Insights: $AppInsightsName
   Monitoring & Analytics enabled

6. App Service: $AppServiceName
   Runtime: Node.js 20 LTS
   Managed Identity: Enabled

CREDENTIALS:
-----------
Stored securely in Azure Key Vault: $KeyVaultName
- MongoDB URI (Cosmos DB)
- JWT Secret
- Azure Storage credentials
- Communication Services connection
- PayPal credentials
- Admin email

NEXT STEPS:
-----------
1. Configure Email Domain:
   - Go to Azure Portal
   - Navigate to Communication Services -> $CommServiceName
   - Click Email -> Provision domains
   - Use Azure Managed Domain (free)
   - Copy sender email and update Key Vault secret

2. Install Azure SDK in your backend:
   cd server
   npm install @azure/identity @azure/keyvault-secrets @azure/storage-blob @azure/communication-email applicationinsights

3. Deploy your application:
   .\deploy-full-app.ps1

4. Monitor your app:
   az webapp log tail --name $AppServiceName --resource-group $ResourceGroup

AZURE PORTAL:
------------
View all resources: https://portal.azure.com
Resource Group: $ResourceGroup

COSTS:
------
- Cosmos DB: Free tier (1000 RU/s)
- Storage: Pay-as-you-go (~$0.02/GB)
- Communication: Pay-per-email (~$0.0004/email)
- App Service: Basic tier (~$13/month) or Free tier
- Key Vault: ~$0.03/10k operations
- App Insights: First 5GB free/month
"@

$deploymentInfo | Out-File -FilePath "azure-deployment-full.txt" -Encoding UTF8

Write-Host "========================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Web App URL: $webAppUrl" -ForegroundColor White
Write-Host ""
Write-Host "Deployment details saved to: azure-deployment-full.txt" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT: Configure email domain in Azure Portal" -ForegroundColor Yellow
Write-Host "  Communication Services -> Email -> Provision domains" -ForegroundColor White
Write-Host ""
