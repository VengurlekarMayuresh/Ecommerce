# Deploy E-Commerce as Docker Container to Azure
$ResourceGroup = "ecommerce-full-rg"
$AppServiceName = "ecomm-app-4379"
$ACRName = "ecommacr4379"  # Azure Container Registry name (must be globally unique)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DOCKER DEPLOYMENT TO AZURE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create Azure Container Registry
Write-Host "[1/5] Creating Azure Container Registry..." -ForegroundColor Cyan
az acr create --resource-group $ResourceGroup --name $ACRName --sku Basic --admin-enabled true
Write-Host "  [SUCCESS] Container Registry created!" -ForegroundColor Green

# Step 2: Build and Push Docker Image
Write-Host "[2/5] Building Docker image..." -ForegroundColor Cyan
Set-Location server
az acr build --registry $ACRName --image ecommerce:latest .
Set-Location ..
Write-Host "  [SUCCESS] Image built and pushed!" -ForegroundColor Green

# Step 3: Get ACR credentials
Write-Host "[3/5] Getting ACR credentials..." -ForegroundColor Cyan
$acrPassword = az acr credential show --name $ACRName --query "passwords[0].value" -o tsv
$acrLoginServer = az acr show --name $ACRName --query loginServer -o tsv
Write-Host "  [SUCCESS] Credentials retrieved!" -ForegroundColor Green

# Step 4: Update App Service to use container
Write-Host "[4/5] Configuring App Service for container..." -ForegroundColor Cyan
az webapp config container set `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --docker-custom-image-name "$acrLoginServer/ecommerce:latest" `
    --docker-registry-server-url "https://$acrLoginServer" `
    --docker-registry-server-user $ACRName `
    --docker-registry-server-password $acrPassword

Write-Host "  [SUCCESS] Container configured!" -ForegroundColor Green

# Step 5: Restart App Service
Write-Host "[5/5] Restarting App Service..." -ForegroundColor Cyan
az webapp restart --name $AppServiceName --resource-group $ResourceGroup
Write-Host "  [SUCCESS] App restarted!" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  DOCKER DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your website: https://$AppServiceName.azurewebsites.net" -ForegroundColor White
Write-Host ""
Write-Host "Wait 2-3 minutes for container to start, then test:" -ForegroundColor Yellow
Write-Host "  curl https://$AppServiceName.azurewebsites.net/api/health" -ForegroundColor Gray
