# Complete Azure E-Commerce Deployment Script
# Includes: Static Web Apps, App Service, Cosmos DB, Key Vault, Storage, Application Insights
#           Communication Services, Notification Hubs, and Azure AD B2C

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "ecommerce-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "production"
)

Write-Host "🚀 Starting Complete Azure E-Commerce Deployment" -ForegroundColor Cyan
Write-Host "This will deploy ALL Azure services including IAM and Notifications" -ForegroundColor Yellow
Write-Host ""

# Check Azure CLI
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI is not installed. Install from https://aka.ms/azure-cli" -ForegroundColor Red
    exit 1
}

# Login
Write-Host "🔐 Logging in to Azure..." -ForegroundColor Cyan
az login

# Create resource group
Write-Host "📦 Creating resource group..." -ForegroundColor Cyan
az group create --name $ResourceGroup --location $Location

# Generate unique names
$Suffix = Get-Random -Maximum 9999
$CosmosAccountName = "ecommerce-cosmos-$Suffix"
$KeyVaultName = "ecommerce-kv-$Suffix"
$StorageAccountName = "ecommstore$Suffix"
$AppServicePlan = "ecommerce-plan"
$AppServiceName = "ecommerce-api-$Suffix"
$StaticWebAppName = "ecommerce-frontend-$Suffix"
$AppInsightsName = "ecommerce-insights"
$CommunicationServiceName = "ecommerce-comm-$Suffix"
$NotificationNamespace = "ecommerce-notify-$Suffix"
$NotificationHub = "ecommerce-hub"

Write-Host ""
Write-Host "📋 Resource Names:" -ForegroundColor Yellow
Write-Host "  Cosmos DB: $CosmosAccountName"
Write-Host "  Key Vault: $KeyVaultName"
Write-Host "  Storage: $StorageAccountName"
Write-Host "  App Service: $AppServiceName"
Write-Host "  Static Web App: $StaticWebAppName"
Write-Host "  Communication: $CommunicationServiceName"
Write-Host "  Notification Hub: $NotificationHub"
Write-Host ""

# 1. Cosmos DB
Write-Host "🗄️  [1/9] Creating Cosmos DB..." -ForegroundColor Cyan
az cosmosdb create `
    --name $CosmosAccountName `
    --resource-group $ResourceGroup `
    --kind MongoDB `
    --server-version 4.2 `
    --default-consistency-level Session `
    --locations regionName=$Location failoverPriority=0 `
    --enable-free-tier true

$CosmosConnectionString = az cosmosdb keys list `
    --name $CosmosAccountName `
    --resource-group $ResourceGroup `
    --type connection-strings `
    --query "connectionStrings[0].connectionString" -o tsv

# 2. Key Vault
Write-Host "🔐 [2/9] Creating Key Vault..." -ForegroundColor Cyan
az keyvault create `
    --name $KeyVaultName `
    --resource-group $ResourceGroup `
    --location $Location

# 3. Storage Account
Write-Host "💾 [3/9] Creating Storage Account..." -ForegroundColor Cyan
az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Standard_LRS

az storage container create `
    --name product-images `
    --account-name $StorageAccountName `
    --public-access blob

$StorageConnectionString = az storage account show-connection-string `
    --name $StorageAccountName `
    --resource-group $ResourceGroup `
    --query connectionString -o tsv

# 4. Application Insights
Write-Host "📊 [4/9] Creating Application Insights..." -ForegroundColor Cyan
az monitor app-insights component create `
    --app $AppInsightsName `
    --location $Location `
    --resource-group $ResourceGroup `
    --application-type web

$AppInsightsConnectionString = az monitor app-insights component show `
    --app $AppInsightsName `
    --resource-group $ResourceGroup `
    --query connectionString -o tsv

# 5. Communication Services
Write-Host "📧 [5/9] Creating Communication Services..." -ForegroundColor Cyan
az communication create `
    --name $CommunicationServiceName `
    --resource-group $ResourceGroup `
    --location "global" `
    --data-location "United States"

$CommunicationConnectionString = az communication list-key `
    --name $CommunicationServiceName `
    --resource-group $ResourceGroup `
    --query primaryConnectionString -o tsv

Write-Host "⚠️  Note: Configure email domain in Azure Portal" -ForegroundColor Yellow
Write-Host "   Communication Services → Email → Provision domains" -ForegroundColor Yellow

# 6. Notification Hub
Write-Host "🔔 [6/9] Creating Notification Hub..." -ForegroundColor Cyan
az notification-hub namespace create `
    --name $NotificationNamespace `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Standard

az notification-hub create `
    --name $NotificationHub `
    --namespace-name $NotificationNamespace `
    --resource-group $ResourceGroup

$NotificationConnectionString = az notification-hub authorization-rule list-keys `
    --resource-group $ResourceGroup `
    --namespace-name $NotificationNamespace `
    --notification-hub-name $NotificationHub `
    --name DefaultFullSharedAccessSignature `
    --query primaryConnectionString -o tsv

Write-Host "⚠️  Note: Configure FCM credentials in Azure Portal" -ForegroundColor Yellow
Write-Host "   Notification Hubs → Settings → Google (FCM)" -ForegroundColor Yellow

# 7. App Service
Write-Host "🌐 [7/9] Creating App Service..." -ForegroundColor Cyan
az appservice plan create `
    --name $AppServicePlan `
    --resource-group $ResourceGroup `
    --location $Location `
    --is-linux `
    --sku B1

az webapp create `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --plan $AppServicePlan `
    --runtime "NODE:18-lts"

az webapp identity assign `
    --name $AppServiceName `
    --resource-group $ResourceGroup

$PrincipalId = az webapp identity show `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --query principalId -o tsv

az keyvault set-policy `
    --name $KeyVaultName `
    --object-id $PrincipalId `
    --secret-permissions get list

# 8. Static Web App
Write-Host "🌍 [8/9] Creating Static Web App..." -ForegroundColor Cyan
az staticwebapp create `
    --name $StaticWebAppName `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Free

$StaticWebAppUrl = az staticwebapp show `
    --name $StaticWebAppName `
    --resource-group $ResourceGroup `
    --query "defaultHostname" -o tsv

# 9. Add Secrets to Key Vault
Write-Host "🔑 [9/9] Adding secrets to Key Vault..." -ForegroundColor Cyan

# Generate JWT secret
$JwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})

# Core secrets
az keyvault secret set --vault-name $KeyVaultName --name "MONGO-URI" --value $CosmosConnectionString | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "JWT-SECRET-KEY" --value $JwtSecret | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "AZURE-STORAGE-CONNECTION-STRING" --value $StorageConnectionString | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "AZURE-COMMUNICATION-CONNECTION-STRING" --value $CommunicationConnectionString | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "AZURE-NOTIFICATION-HUB-CONNECTION-STRING" --value $NotificationConnectionString | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "AZURE-NOTIFICATION-HUB-NAME" --value $NotificationHub | Out-Null

# Interactive secrets
Write-Host ""
Write-Host "Please provide additional credentials:" -ForegroundColor Yellow

# PayPal
$PaypalClientId = Read-Host "PayPal Client ID"
$PaypalSecret = Read-Host "PayPal Client Secret"
$PaypalMode = Read-Host "PayPal Mode (sandbox/live)"
az keyvault secret set --vault-name $KeyVaultName --name "PAYPAL-CLIENT-ID" --value $PaypalClientId | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "PAYPAL-CLIENT-SECRET" --value $PaypalSecret | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "PAYPAL-MODE" --value $PaypalMode | Out-Null

# Cloudinary (optional)
$UseCloudinary = Read-Host "Use Cloudinary? (y/n)"
if ($UseCloudinary -eq "y") {
    $CloudinaryName = Read-Host "Cloudinary Cloud Name"
    $CloudinaryKey = Read-Host "Cloudinary API Key"
    $CloudinarySecret = Read-Host "Cloudinary API Secret"
    az keyvault secret set --vault-name $KeyVaultName --name "CLOUDINARY-CLOUD-NAME" --value $CloudinaryName | Out-Null
    az keyvault secret set --vault-name $KeyVaultName --name "CLOUDINARY-API-KEY" --value $CloudinaryKey | Out-Null
    az keyvault secret set --vault-name $KeyVaultName --name "CLOUDINARY-API-SECRET" --value $CloudinarySecret | Out-Null
}

# Email sender
$SenderEmail = Read-Host "Email sender address (from Communication Services)"
az keyvault secret set --vault-name $KeyVaultName --name "AZURE-COMMUNICATION-SENDER-ADDRESS" --value $SenderEmail | Out-Null

$AdminEmail = Read-Host "Admin notification email"
az keyvault secret set --vault-name $KeyVaultName --name "ADMIN-NOTIFICATION-EMAIL" --value $AdminEmail | Out-Null

# Configure App Service
az webapp config appsettings set `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --settings `
        KEY_VAULT_NAME=$KeyVaultName `
        NODE_ENV=production `
        PORT=8080 `
        FRONTEND_URL=https://$StaticWebAppUrl `
        APPLICATIONINSIGHTS_CONNECTION_STRING=$AppInsightsConnectionString

Write-Host ""
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Resource URLs:" -ForegroundColor Cyan
Write-Host "  Frontend: https://$StaticWebAppUrl" -ForegroundColor White
Write-Host "  Backend API: https://$AppServiceName.azurewebsites.net" -ForegroundColor White
Write-Host "  Key Vault: https://$KeyVaultName.vault.azure.net" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Important Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Configure Azure AD B2C tenant (see AZURE_IAM_NOTIFICATIONS.md)" -ForegroundColor White
Write-Host "  2. Configure email domain in Communication Services" -ForegroundColor White
Write-Host "  3. Add FCM credentials to Notification Hub" -ForegroundColor White
Write-Host "  4. Configure GitHub integration for Static Web App" -ForegroundColor White
Write-Host "  5. Add GitHub secrets for CI/CD" -ForegroundColor White
Write-Host "  6. Update backend to use new IAM middleware" -ForegroundColor White
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "  - AZURE_DEPLOYMENT.md - Core services setup" -ForegroundColor White
Write-Host "  - AZURE_IAM_NOTIFICATIONS.md - IAM and notifications setup" -ForegroundColor White
Write-Host ""
Write-Host "Tip: Install backend dependencies:" -ForegroundColor Yellow
Write-Host "  cd server" -ForegroundColor White
Write-Host "  npm install @azure/identity @azure/keyvault-secrets @azure/storage-blob @azure/communication-email @azure/msal-node azure-sb applicationinsights uuid" -ForegroundColor White
