# Azure E-commerce Deployment Script
param(
    [string]$ResourceGroup = "ecommerce-rg",
    [string]$Location = "eastus",
    [string]$AppName = "radhika-ecommerce-api",
    [string]$StaticAppName = "radhika-ecommerce-frontend"
)

Write-Host "Starting Azure deployment..." -ForegroundColor Cyan

# Create Resource Group
Write-Host "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location

# Create Storage Account
Write-Host "Creating storage account..." -ForegroundColor Yellow
$timestamp = Get-Date -UFormat "%s" -Replace "\.",""
$storageName = "ecommstore$timestamp"
az storage account create `
    --name $storageName `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2

# Get storage connection string
$storageConnection = az storage account show-connection-string `
    --name $storageName `
    --resource-group $ResourceGroup `
    --output tsv

Write-Host "Storage connection string: $storageConnection" -ForegroundColor Green

# Create blob container
az storage container create `
    --name product-images `
    --account-name $storageName `
    --public-access blob

# Create Application Insights
Write-Host "Creating Application Insights..." -ForegroundColor Yellow
az monitor app-insights component create `
    --app ecommerce-insights `
    --resource-group $ResourceGroup `
    --location $Location `
    --application-type web

# Get App Insights connection string
$appInsightsConnection = az monitor app-insights component show `
    --app ecommerce-insights `
    --resource-group $ResourceGroup `
    --query connectionString `
    --output tsv

Write-Host "App Insights connection string obtained" -ForegroundColor Green

# Create App Service Plan
Write-Host "Creating App Service Plan..." -ForegroundColor Yellow
az appservice plan create `
    --name ecommerce-plan `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku B1 `
    --is-linux

# Create Web App
Write-Host "Creating Web App: $AppName" -ForegroundColor Yellow
az webapp create `
    --name $AppName `
    --resource-group $ResourceGroup `
    --plan ecommerce-plan `
    --runtime "NODE:20-lts"

# Configure environment variables
Write-Host "Configuring environment variables..." -ForegroundColor Yellow
az webapp config appsettings set `
    --name $AppName `
    --resource-group $ResourceGroup `
    --settings `
        NODE_ENV=production `
        PORT=8080 `
        MONGO_DBURL="mongodb+srv://onlinemayuresh29:Mayuresh%409321@e-com.06wkco0.mongodb.net/" `
        SECRET_KEY="onlinemayuresh29" `
        AZURE_STORAGE_CONNECTION_STRING="$storageConnection" `
        APPLICATIONINSIGHTS_CONNECTION_STRING="$appInsightsConnection" `
        CLOUDINARY_CLOUD_NAME="ds20dwlrs" `
        CLOUDINARY_API_KEY="458753332856375" `
        CLOUDINARY_API_SECRET="tcqI98ArkHPoSZt2lPsuDQQ5cfs"

# Enable logging
az webapp log config `
    --name $AppName `
    --resource-group $ResourceGroup `
    --application-logging filesystem `
    --web-server-logging filesystem

# Get publish profile
Write-Host "Getting publish profile..." -ForegroundColor Yellow
$publishProfile = az webapp deployment list-publishing-profiles `
    --name $AppName `
    --resource-group $ResourceGroup `
    --xml

# Save publish profile
$publishProfile | Out-File -FilePath "publish-profile.xml" -Encoding UTF8
Write-Host "Publish profile saved to: publish-profile.xml" -ForegroundColor Green

# Summary
Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
Write-Host "Backend URL: https://$AppName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "Storage Account: $storageName" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Check publish-profile.xml for GitHub secrets"
Write-Host "2. Deploy code via GitHub Actions or manual upload"
Write-Host "3. Test: https://$AppName.azurewebsites.net/api/health"
