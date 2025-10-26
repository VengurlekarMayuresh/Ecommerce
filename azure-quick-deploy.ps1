# Azure E-commerce Quick Deploy Script (PowerShell)
# Run this script to quickly deploy your e-commerce app to Azure

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup = "ecommerce-rg",
    
    [Parameter(Mandatory=$true)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$true)]
    [string]$AppName = "ecomm-api",
    
    [Parameter(Mandatory=$true)]
    [string]$StaticAppName = "ecommerce-frontend"
)

Write-Host "🚀 Starting Azure E-commerce Deployment..." -ForegroundColor Cyan

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI not found. Please install it first." -ForegroundColor Red
    Write-Host "Download from: https://aka.ms/installazurecliwindows" -ForegroundColor Yellow
    exit 1
}

# Login check
Write-Host "📝 Checking Azure login..." -ForegroundColor Yellow
$account = az account show 2>$null
if (-not $account) {
    Write-Host "Please login to Azure..." -ForegroundColor Yellow
    az login
}

# Create Resource Group
Write-Host "📦 Creating resource group: $ResourceGroup" -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location

# Create Storage Account
Write-Host "💾 Creating storage account..." -ForegroundColor Yellow
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$storageName = "ecommstore$timestamp"
az storage account create `
    --name $storageName `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2

$storageConnection = az storage account show-connection-string `
    --name $storageName `
    --resource-group $ResourceGroup `
    --output tsv

Write-Host "✅ Storage connection string: $storageConnection" -ForegroundColor Green

# Create container
az storage container create `
    --name product-images `
    --account-name $storageName `
    --public-access blob

# Create Application Insights
Write-Host "📊 Creating Application Insights..." -ForegroundColor Yellow
az monitor app-insights component create `
    --app ecommerce-insights `
    --resource-group $ResourceGroup `
    --location $Location `
    --application-type web

$appInsightsConnection = az monitor app-insights component show `
    --app ecommerce-insights `
    --resource-group $ResourceGroup `
    --query connectionString `
    --output tsv

Write-Host "✅ App Insights connection string obtained" -ForegroundColor Green

# Create App Service Plan
Write-Host "🖥️  Creating App Service Plan..." -ForegroundColor Yellow
az appservice plan create `
    --name ecommerce-plan `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku B1 `
    --is-linux

# Create Web App
Write-Host "🌐 Creating Web App: $AppName" -ForegroundColor Yellow
az webapp create `
    --name $AppName `
    --resource-group $ResourceGroup `
    --plan ecommerce-plan `
    --runtime "NODE:20-lts"

Write-Host "⚙️  Configuring environment variables..." -ForegroundColor Yellow
Write-Host "⚠️  Please update these in Azure Portal with your actual values!" -ForegroundColor Red

# Get publish profile
Write-Host "📄 Getting publish profile..." -ForegroundColor Yellow
$publishProfile = az webapp deployment list-publishing-profiles `
    --name $AppName `
    --resource-group $ResourceGroup `
    --xml

# Save to file
$publishProfile | Out-File -FilePath "publish-profile.xml" -Encoding UTF8
Write-Host "✅ Publish profile saved to: publish-profile.xml" -ForegroundColor Green

# Create Static Web App
Write-Host "🎨 Creating Static Web App: $StaticAppName" -ForegroundColor Yellow
Write-Host "⚠️  You'll need to connect this to GitHub manually or provide GitHub token" -ForegroundColor Yellow

# Summary
Write-Host "`n✅ Deployment resources created successfully!" -ForegroundColor Green
Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Update server environment variables in Azure Portal" -ForegroundColor White
Write-Host "2. Add GitHub secrets:" -ForegroundColor White
Write-Host "   - AZURE_WEBAPP_PUBLISH_PROFILE (from publish-profile.xml)" -ForegroundColor Gray
Write-Host "   - AZURE_STATIC_WEB_APPS_API_TOKEN (from Static Web App)" -ForegroundColor Gray
Write-Host "3. Push code to GitHub to trigger deployment" -ForegroundColor White
Write-Host "`n🌐 Backend URL: https://$AppName.azurewebsites.net" -ForegroundColor Green
Write-Host "📚 Full guide: See AZURE-DEPLOYMENT.md" -ForegroundColor Yellow

Write-Host "`n🎉 Setup complete!" -ForegroundColor Green
