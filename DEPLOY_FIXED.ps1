# FIXED DEPLOYMENT - Linux-compatible
$ResourceGroup = "ecommerce-full-rg"
$AppServiceName = "ecomm-app-4379"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FIXED DEPLOYMENT TO AZURE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Clean up
Write-Host "[1/4] Cleaning up..." -ForegroundColor Cyan
Remove-Item "deploy-temp" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "deploy.tar.gz" -Force -ErrorAction SilentlyContinue
Write-Host "  [SUCCESS] Cleaned!" -ForegroundColor Green

# Copy server files
Write-Host "[2/4] Preparing deployment..." -ForegroundColor Cyan
Copy-Item -Path "server" -Destination "deploy-temp" -Recurse
Remove-Item "deploy-temp/.env" -Force -ErrorAction SilentlyContinue
Remove-Item "deploy-temp/node_modules" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  [SUCCESS] Files prepared!" -ForegroundColor Green

# Create tar.gz (Linux-compatible)
Write-Host "[3/4] Creating Linux-compatible archive..." -ForegroundColor Cyan
Set-Location deploy-temp
tar -czf ../deploy.tar.gz *
Set-Location ..
Write-Host "  [SUCCESS] Archive created!" -ForegroundColor Green

# Deploy
Write-Host "[4/4] Deploying to Azure..." -ForegroundColor Cyan
az webapp deploy `
    --resource-group $ResourceGroup `
    --name $AppServiceName `
    --src-path "deploy.tar.gz" `
    --type tar.gz `
    --async false

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Testing in 30 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

$response = curl https://ecomm-app-4379.azurewebsites.net/api/health -UseBasicParsing -ErrorAction SilentlyContinue

if ($response.StatusCode -eq 200) {
    Write-Host "✅ SUCCESS! Application is running!" -ForegroundColor Green
    Write-Host $response.Content -ForegroundColor White
} else {
    Write-Host "⚠️ Still checking... May need more time" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Your website: https://ecomm-app-4379.azurewebsites.net" -ForegroundColor Cyan

# Clean up
Remove-Item "deploy-temp" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "deploy.tar.gz" -Force -ErrorAction SilentlyContinue
