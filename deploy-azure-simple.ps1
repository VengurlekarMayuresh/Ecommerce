# Simplified Azure Deployment - Combined Frontend + Backend
# Works with Azure for Students limitations

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "ecommerce-app-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastasia"
)

Write-Host "[*] Starting Simplified Azure E-Commerce Deployment" -ForegroundColor Cyan
Write-Host "    Hosting both frontend and backend in a single Web App" -ForegroundColor Yellow
Write-Host ""

# Check Azure CLI
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Azure CLI is not installed" -ForegroundColor Red
    exit 1
}

# Generate unique suffix
$Suffix = Get-Random -Maximum 9999
$AppServicePlan = "ecommerce-plan-$Suffix"
$AppServiceName = "ecommerce-app-$Suffix"
$StorageAccountName = "ecommstore$Suffix"

Write-Host "Resource Names:" -ForegroundColor Yellow
Write-Host "  Resource Group: $ResourceGroup"
Write-Host "  App Service: $AppServiceName"
Write-Host "  Storage: $StorageAccountName"
Write-Host "  Location: $Location"
Write-Host ""

# Create resource group
Write-Host "[1/3] Creating resource group..." -ForegroundColor Cyan
az group create --name $ResourceGroup --location $Location

# Create storage account for MongoDB (Azure Cosmos DB alternative)
Write-Host "[2/3] Creating Storage Account..." -ForegroundColor Cyan
az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2

$StorageKey = az storage account keys list `
    --account-name $StorageAccountName `
    --resource-group $ResourceGroup `
    --query "[0].value" -o tsv

# Create App Service Plan (Free tier)
Write-Host "[3/3] Creating App Service..." -ForegroundColor Cyan
az appservice plan create `
    --name $AppServicePlan `
    --resource-group $ResourceGroup `
    --location $Location `
    --is-linux `
    --sku F1

# Get available runtimes
Write-Host "[*] Checking available Node.js runtimes..." -ForegroundColor Cyan
$runtimes = az webapp list-runtimes --os-type linux --output json | ConvertFrom-Json
$nodeRuntime = $runtimes | Where-Object { $_ -like "NODE*20*" } | Select-Object -First 1

if (-not $nodeRuntime) {
    $nodeRuntime = $runtimes | Where-Object { $_ -like "NODE*18*" } | Select-Object -First 1
}

if (-not $nodeRuntime) {
    Write-Host "[ERROR] No suitable Node.js runtime found" -ForegroundColor Red
    Write-Host "Available runtimes:" -ForegroundColor Yellow
    $runtimes | Where-Object { $_ -like "NODE*" } | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host "[*] Using runtime: $nodeRuntime" -ForegroundColor Green

# Create Web App
az webapp create `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --plan $AppServicePlan `
    --runtime $nodeRuntime

Write-Host ""
Write-Host "Please provide configuration:" -ForegroundColor Yellow
Write-Host ""

# Get MongoDB connection string
$MongoUri = Read-Host "MongoDB Connection String (or press Enter to use local MongoDB later)"
if ([string]::IsNullOrWhiteSpace($MongoUri)) {
    $MongoUri = "mongodb://localhost:27017/ecommerce"
    Write-Host "[WARNING] Using local MongoDB - you'll need to migrate to cloud database" -ForegroundColor Yellow
}

# Get JWT secret
$JwtSecret = Read-Host "JWT Secret (or press Enter to auto-generate)"
if ([string]::IsNullOrWhiteSpace($JwtSecret)) {
    $JwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    Write-Host "[*] Generated JWT Secret: $JwtSecret" -ForegroundColor Green
}

# PayPal credentials
$PaypalClientId = Read-Host "PayPal Client ID"
$PaypalSecret = Read-Host "PayPal Client Secret"
$PaypalMode = Read-Host "PayPal Mode (sandbox/live)"

# Cloudinary (optional)
$UseCloudinary = Read-Host "Use Cloudinary for images? (y/n)"
if ($UseCloudinary -eq "y") {
    $CloudinaryName = Read-Host "Cloudinary Cloud Name"
    $CloudinaryKey = Read-Host "Cloudinary API Key"
    $CloudinarySecret = Read-Host "Cloudinary API Secret"
}

# Configure App Service settings
Write-Host ""
Write-Host "[*] Configuring App Service..." -ForegroundColor Cyan

$settings = @{
    "MONGO_URI" = $MongoUri
    "SECRET_KEY" = $JwtSecret
    "PAYPAL_CLIENT_ID" = $PaypalClientId
    "PAYPAL_CLIENT_SECRET" = $PaypalSecret
    "PAYPAL_MODE" = $PaypalMode
    "NODE_ENV" = "production"
    "PORT" = "8080"
    "WEBSITE_NODE_DEFAULT_VERSION" = "~20"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
}

if ($UseCloudinary -eq "y") {
    $settings["CLOUDINARY_CLOUD_NAME"] = $CloudinaryName
    $settings["CLOUDINARY_API_KEY"] = $CloudinaryKey
    $settings["CLOUDINARY_API_SECRET"] = $CloudinarySecret
}

# Convert settings to Azure CLI format
$settingsString = ($settings.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join " "

az webapp config appsettings set `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --settings $settingsString

# Enable logging
az webapp log config `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --application-logging filesystem `
    --detailed-error-messages true `
    --failed-request-tracing true `
    --web-server-logging filesystem

# Get deployment credentials
Write-Host ""
Write-Host "[*] Getting deployment credentials..." -ForegroundColor Cyan
$deployUser = az webapp deployment user show --query publishingUserName -o tsv

if ([string]::IsNullOrWhiteSpace($deployUser)) {
    Write-Host "[*] Setting up deployment user..." -ForegroundColor Cyan
    $deployUsername = "ecommerce-deploy-$Suffix"
    $deployPassword = -join ((65..90) + (97..122) + (48..57) + 33..47 | Get-Random -Count 16 | ForEach-Object {[char]$_})
    
    az webapp deployment user set --user-name $deployUsername --password $deployPassword
    
    Write-Host ""
    Write-Host "Deployment Credentials:" -ForegroundColor Yellow
    Write-Host "  Username: $deployUsername" -ForegroundColor White
    Write-Host "  Password: $deployPassword" -ForegroundColor White
    Write-Host ""
}

# Get publish profile
Write-Host "[*] Downloading publish profile..." -ForegroundColor Cyan
az webapp deployment list-publishing-profiles `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --xml > azure-publish-profile.xml

$webAppUrl = "https://$AppServiceName.azurewebsites.net"

Write-Host ""
Write-Host "[SUCCESS] Deployment Infrastructure Ready!" -ForegroundColor Green
Write-Host ""
Write-Host "=======================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT INFORMATION" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Web App URL: $webAppUrl" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "App Service Name: $AppServiceName" -ForegroundColor White
Write-Host ""
Write-Host "Publish Profile: azure-publish-profile.xml" -ForegroundColor White
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Build your application:" -ForegroundColor White
Write-Host "   cd client && npm install && npm run build" -ForegroundColor Gray
Write-Host "   cd ../server && npm install" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Deploy using one of these methods:" -ForegroundColor White
Write-Host "   A) ZIP Deploy (Recommended):" -ForegroundColor Cyan
Write-Host "      Run: .\deploy-app.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "   B) Git Deploy:" -ForegroundColor Cyan
Write-Host "      git remote add azure https://$AppServiceName.scm.azurewebsites.net/$AppServiceName.git" -ForegroundColor Gray
Write-Host "      git push azure main" -ForegroundColor Gray
Write-Host ""
Write-Host "   C) GitHub Actions:" -ForegroundColor Cyan
Write-Host "      Add azure-publish-profile.xml content to GitHub Secrets" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Monitor logs:" -ForegroundColor White
Write-Host "   az webapp log tail --name $AppServiceName --resource-group $ResourceGroup" -ForegroundColor Gray
Write-Host ""

# Save deployment info
@"
DEPLOYMENT INFORMATION
======================
Web App URL: $webAppUrl
Resource Group: $ResourceGroup
App Service Name: $AppServiceName
Location: $Location
Runtime: $nodeRuntime

MongoDB URI: $MongoUri
JWT Secret: $JwtSecret

Publish Profile: azure-publish-profile.xml

NEXT STEPS:
1. Build the application
2. Deploy using deploy-app.ps1
3. Configure custom domain (optional)
"@ | Out-File -FilePath "deployment-info.txt" -Encoding UTF8

Write-Host "Deployment info saved to: deployment-info.txt" -ForegroundColor Green
