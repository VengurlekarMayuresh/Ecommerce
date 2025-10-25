# Azure E-Commerce Deployment Script
# Run this script to deploy your e-commerce application to Azure

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "ecommerce-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "production"
)

Write-Host "🚀 Starting Azure E-Commerce Deployment" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Yellow
Write-Host "Location: $Location" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host ""

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI is not installed. Please install it from https://aka.ms/azure-cli" -ForegroundColor Red
    exit 1
}

# Login to Azure
Write-Host "🔐 Logging in to Azure..." -ForegroundColor Cyan
az login

# Create resource group
Write-Host "📦 Creating resource group..." -ForegroundColor Cyan
az group create --name $ResourceGroup --location $Location

# Variables
$CosmosAccountName = "ecommerce-cosmos-db-$(Get-Random -Maximum 9999)"
$KeyVaultName = "ecommerce-kv-$(Get-Random -Maximum 9999)"
$StorageAccountName = "ecommstore$(Get-Random -Maximum 9999)"
$AppServicePlan = "ecommerce-plan"
$AppServiceName = "ecommerce-api-$(Get-Random -Maximum 9999)"
$StaticWebAppName = "ecommerce-frontend-$(Get-Random -Maximum 9999)"
$AppInsightsName = "ecommerce-insights"

Write-Host "Generated resource names:" -ForegroundColor Yellow
Write-Host "  Cosmos DB: $CosmosAccountName"
Write-Host "  Key Vault: $KeyVaultName"
Write-Host "  Storage: $StorageAccountName"
Write-Host "  App Service: $AppServiceName"
Write-Host "  Static Web App: $StaticWebAppName"
Write-Host ""

# Create Cosmos DB
Write-Host "🗄️ Creating Cosmos DB (MongoDB API)..." -ForegroundColor Cyan
az cosmosdb create `
    --name $CosmosAccountName `
    --resource-group $ResourceGroup `
    --kind MongoDB `
    --server-version 4.2 `
    --default-consistency-level Session `
    --locations regionName=$Location failoverPriority=0 isZoneRedundant=False `
    --enable-free-tier true

# Get Cosmos DB connection string
Write-Host "📝 Getting Cosmos DB connection string..." -ForegroundColor Cyan
$CosmosConnectionString = az cosmosdb keys list `
    --name $CosmosAccountName `
    --resource-group $ResourceGroup `
    --type connection-strings `
    --query "connectionStrings[0].connectionString" -o tsv

# Create Key Vault
Write-Host "🔐 Creating Key Vault..." -ForegroundColor Cyan
az keyvault create `
    --name $KeyVaultName `
    --resource-group $ResourceGroup `
    --location $Location

# Add secrets to Key Vault
Write-Host "🔑 Adding secrets to Key Vault..." -ForegroundColor Cyan
Write-Host "Please provide the following secrets:"

$JwtSecret = Read-Host "JWT Secret Key (or press Enter to generate)"
if ([string]::IsNullOrWhiteSpace($JwtSecret)) {
    $JwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
}

az keyvault secret set --vault-name $KeyVaultName --name "MONGO-URI" --value $CosmosConnectionString | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "JWT-SECRET-KEY" --value $JwtSecret | Out-Null

$UseCloudinary = Read-Host "Use Cloudinary for images? (y/n)"
if ($UseCloudinary -eq "y") {
    $CloudinaryName = Read-Host "Cloudinary Cloud Name"
    $CloudinaryKey = Read-Host "Cloudinary API Key"
    $CloudinarySecret = Read-Host "Cloudinary API Secret"
    
    az keyvault secret set --vault-name $KeyVaultName --name "CLOUDINARY-CLOUD-NAME" --value $CloudinaryName | Out-Null
    az keyvault secret set --vault-name $KeyVaultName --name "CLOUDINARY-API-KEY" --value $CloudinaryKey | Out-Null
    az keyvault secret set --vault-name $KeyVaultName --name "CLOUDINARY-API-SECRET" --value $CloudinarySecret | Out-Null
}

$PaypalClientId = Read-Host "PayPal Client ID"
$PaypalSecret = Read-Host "PayPal Client Secret"
$PaypalMode = Read-Host "PayPal Mode (sandbox/live)"

az keyvault secret set --vault-name $KeyVaultName --name "PAYPAL-CLIENT-ID" --value $PaypalClientId | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "PAYPAL-CLIENT-SECRET" --value $PaypalSecret | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "PAYPAL-MODE" --value $PaypalMode | Out-Null

# Create Storage Account
Write-Host "💾 Creating Azure Storage Account..." -ForegroundColor Cyan
az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2

# Create container
az storage container create `
    --name product-images `
    --account-name $StorageAccountName `
    --public-access blob

$StorageConnectionString = az storage account show-connection-string `
    --name $StorageAccountName `
    --resource-group $ResourceGroup `
    --query connectionString -o tsv

az keyvault secret set --vault-name $KeyVaultName --name "AZURE-STORAGE-CONNECTION-STRING" --value $StorageConnectionString | Out-Null

# Create Application Insights
Write-Host "📊 Creating Application Insights..." -ForegroundColor Cyan
az monitor app-insights component create `
    --app $AppInsightsName `
    --location $Location `
    --resource-group $ResourceGroup `
    --application-type web

$AppInsightsConnectionString = az monitor app-insights component show `
    --app $AppInsightsName `
    --resource-group $ResourceGroup `
    --query connectionString -o tsv

# Create App Service Plan
Write-Host "🖥️ Creating App Service Plan..." -ForegroundColor Cyan
az appservice plan create `
    --name $AppServicePlan `
    --resource-group $ResourceGroup `
    --location $Location `
    --is-linux `
    --sku B1

# Create App Service
Write-Host "🌐 Creating App Service..." -ForegroundColor Cyan
az webapp create `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --plan $AppServicePlan `
    --runtime "NODE:18-lts"

# Enable managed identity
Write-Host "🔐 Enabling managed identity..." -ForegroundColor Cyan
az webapp identity assign `
    --name $AppServiceName `
    --resource-group $ResourceGroup

$PrincipalId = az webapp identity show `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --query principalId -o tsv

# Grant Key Vault access
az keyvault set-policy `
    --name $KeyVaultName `
    --object-id $PrincipalId `
    --secret-permissions get list

# Configure App Service settings
Write-Host "⚙️ Configuring App Service settings..." -ForegroundColor Cyan
az webapp config appsettings set `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --settings `
        KEY_VAULT_NAME=$KeyVaultName `
        NODE_ENV=production `
        PORT=8080 `
        APPLICATIONINSIGHTS_CONNECTION_STRING=$AppInsightsConnectionString

# Create Static Web App
Write-Host "🌍 Creating Static Web App..." -ForegroundColor Cyan
Write-Host "⚠️ Note: You'll need to configure GitHub integration manually in Azure Portal" -ForegroundColor Yellow

az staticwebapp create `
    --name $StaticWebAppName `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Free

$StaticWebAppUrl = az staticwebapp show `
    --name $StaticWebAppName `
    --resource-group $ResourceGroup `
    --query "defaultHostname" -o tsv

# Update App Service CORS
az webapp config appsettings set `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --settings FRONTEND_URL=https://$StaticWebAppUrl

Write-Host ""
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Resource URLs:" -ForegroundColor Cyan
Write-Host "  Frontend: https://$StaticWebAppUrl" -ForegroundColor White
Write-Host "  Backend API: https://$AppServiceName.azurewebsites.net" -ForegroundColor White
Write-Host "  Key Vault: https://$KeyVaultName.vault.azure.net" -ForegroundColor White
Write-Host ""
Write-Host "🔄 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Configure GitHub integration for Static Web App in Azure Portal"
Write-Host "  2. Add GitHub secrets for CI/CD"
Write-Host "  3. Update client/.env.production with backend API URL"
Write-Host "  4. Push to main branch to trigger deployment"
Write-Host ""
Write-Host "📚 For detailed instructions, see AZURE_DEPLOYMENT.md" -ForegroundColor Yellow
