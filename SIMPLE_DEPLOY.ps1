# SIMPLEST DEPLOYMENT - Let Azure build on Linux
$ResourceGroup = "ecommerce-full-rg"
$AppServiceName = "ecomm-app-4379"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SIMPLE AZURE DEPLOYMENT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Preparing clean server package..." -ForegroundColor Cyan
Set-Location server

# Remove files that shouldn't be deployed
Remove-Item ".env" -Force -ErrorAction SilentlyContinue
Remove-Item "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "*.log" -Force -ErrorAction SilentlyContinue

Write-Host "  [SUCCESS] Package ready!" -ForegroundColor Green

Write-Host "[2/3] Creating deployment package..." -ForegroundColor Cyan
$zipPath = "../server-clean.zip"
Compress-Archive -Path * -DestinationPath $zipPath -Force
Set-Location ..
Write-Host "  [SUCCESS] ZIP created!" -ForegroundColor Green

Write-Host "[3/3] Deploying to Azure (this will take 3-5 min)..." -ForegroundColor Cyan
az webapp deploy `
    --resource-group $ResourceGroup `
    --name $AppServiceName `
    --src-path "server-clean.zip" `
    --type zip

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT INITIATED!" -ForegroundColor Green  
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Waiting 60 seconds for app to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

Write-Host "Testing application..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://ecomm-app-4379.azurewebsites.net/api/health" -UseBasicParsing
    Write-Host "✅ SUCCESS! Application is running!" -ForegroundColor Green
    Write-Host $response.Content -ForegroundColor White
} catch {
    Write-Host "⚠️ App may still be starting. Check manually:" -ForegroundColor Yellow
    Write-Host "  https://ecomm-app-4379.azurewebsites.net/api/health" -ForegroundColor White
}

Write-Host ""
Write-Host "Monitor logs:" -ForegroundColor Yellow
Write-Host "  az webapp log tail --name $AppServiceName --resource-group $ResourceGroup" -ForegroundColor Gray

# Clean up
Remove-Item "server-clean.zip" -Force -ErrorAction SilentlyContinue
