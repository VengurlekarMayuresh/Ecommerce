# Deploy E-Commerce Website to Azure
# Builds frontend, packages backend with Azure SDKs, and deploys

$ResourceGroup = "ecommerce-full-rg"
$AppServiceName = "ecomm-app-4379"
$StorageAccountName = "ecommstore4379"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOYING WEBSITE TO AZURE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build Frontend
Write-Host "[1/4] Building Frontend..." -ForegroundColor Cyan
Set-Location client

Write-Host "  Installing dependencies..." -ForegroundColor Gray
npm install

Write-Host "  Building production bundle..." -ForegroundColor Gray
npm run build

if (-not (Test-Path "dist")) {
    Write-Host "  [ERROR] Frontend build failed - dist folder not found" -ForegroundColor Red
    exit 1
}

Write-Host "  [SUCCESS] Frontend built!" -ForegroundColor Green
Set-Location ..

# Step 2: Prepare Backend with Azure Integration
Write-Host "[2/4] Preparing Backend..." -ForegroundColor Cyan
Set-Location server

Write-Host "  Installing dependencies..." -ForegroundColor Gray
npm install --production

Write-Host "  [SUCCESS] Backend prepared!" -ForegroundColor Green
Set-Location ..

# Step 3: Create Deployment Package
Write-Host "[3/4] Creating deployment package..." -ForegroundColor Cyan

# Clean up old deployment
if (Test-Path "deploy-package") {
    Remove-Item "deploy-package" -Recurse -Force
}
New-Item -ItemType Directory -Path "deploy-package" | Out-Null

# Copy server files
Write-Host "  Copying server files..." -ForegroundColor Gray
Copy-Item -Path "server\*" -Destination "deploy-package\" -Recurse -Exclude "node_modules","*.log"

# Copy built frontend
Write-Host "  Copying frontend build..." -ForegroundColor Gray
New-Item -ItemType Directory -Path "deploy-package\public" -Force | Out-Null
Copy-Item -Path "client\dist\*" -Destination "deploy-package\public\" -Recurse

# Create startup server file
Write-Host "  Creating startup script..." -ForegroundColor Gray
$serverScript = @"
const express = require('express');
const path = require('path');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const mongoose = require('mongoose');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors({ 
    origin: true, 
    credentials: true 
}));
app.use(express.json({ limit: '50mb' }));
app.use(cookieParser());

// API Routes
const authRouter = require('./routes/auth/auth-routes');
const adminProductRouter = require('./routes/admin/admin-products-routes');
const shopProductRouter = require('./routes/shop/shop-products-routes');
const shopCartRouter = require('./routes/shop/shop-cart-routes');
const shopAddressRouter = require('./routes/shop/shop-address-routes');
const shopOrderRouter = require('./routes/shop/shop-order-routes');
const adminOrderRouter = require('./routes/admin/admin-order-routes');
const shopSearchRouter = require('./routes/shop/shop-search-routes');
const shopReviewRouter = require('./routes/shop/shop-review-routes');
const commonFeatureRouter = require('./routes/common/common-feature-routes');

app.use('/api/auth', authRouter);
app.use('/api/admin/products', adminProductRouter);
app.use('/api/admin/orders', adminOrderRouter);
app.use('/api/shop/products', shopProductRouter);
app.use('/api/shop/cart', shopCartRouter);
app.use('/api/shop/address', shopAddressRouter);
app.use('/api/shop/order', shopOrderRouter);
app.use('/api/shop/search', shopSearchRouter);
app.use('/api/shop/review', shopReviewRouter);
app.use('/api/common/feature', commonFeatureRouter);

// Serve static files from React app
app.use(express.static(path.join(__dirname, 'public')));

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV 
    });
});

// All other routes serve React app
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Database connection
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/ecommerce';

mongoose.connect(MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
})
.then(() => {
    console.log('[SUCCESS] MongoDB connected');
    console.log('[INFO] Database:', MONGO_URI.split('@')[1] || 'localhost');
})
.catch(err => {
    console.error('[ERROR] MongoDB connection failed:', err.message);
});

// Start server
app.listen(PORT, () => {
    console.log('========================================');
    console.log(\`[SUCCESS] Server running on port \${PORT}\`);
    console.log(\`[INFO] Environment: \${process.env.NODE_ENV || 'development'}\`);
    console.log(\`[INFO] Azure Key Vault: \${process.env.KEY_VAULT_NAME || 'Not configured'}\`);
    console.log('========================================');
});

// Error handling
process.on('unhandledRejection', (err) => {
    console.error('[ERROR] Unhandled Rejection:', err);
});
"@

$serverScript | Out-File -FilePath "deploy-package\server.js" -Encoding UTF8

# Update package.json
$packageJson = @"
{
  "name": "ecommerce-azure",
  "version": "1.0.0",
  "description": "E-commerce application on Azure",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
"@

$packageJson | Out-File -FilePath "deploy-package\package.json" -Encoding UTF8

# Merge dependencies from original package.json
if (Test-Path "server\package.json") {
    $originalPkg = Get-Content "server\package.json" -Raw | ConvertFrom-Json
    $deployPkg = Get-Content "deploy-package\package.json" -Raw | ConvertFrom-Json
    $deployPkg | Add-Member -MemberType NoteProperty -Name "dependencies" -Value $originalPkg.dependencies -Force
    $deployPkg | ConvertTo-Json -Depth 10 | Out-File -FilePath "deploy-package\package.json" -Encoding UTF8
}

# Create .deployment file for Azure
@"
[config]
SCM_DO_BUILD_DURING_DEPLOYMENT=true
"@ | Out-File -FilePath "deploy-package\.deployment" -Encoding ASCII

Write-Host "  [SUCCESS] Deployment package created!" -ForegroundColor Green

# Create ZIP
Write-Host "  Creating ZIP archive..." -ForegroundColor Gray
if (Test-Path "deploy.zip") {
    Remove-Item "deploy.zip" -Force
}
Compress-Archive -Path "deploy-package\*" -DestinationPath "deploy.zip" -Force

Write-Host "  [SUCCESS] ZIP created!" -ForegroundColor Green

# Step 4: Deploy to Azure
Write-Host "[4/4] Deploying to Azure..." -ForegroundColor Cyan
Write-Host "  This may take 5-10 minutes..." -ForegroundColor Yellow
Write-Host ""

az webapp deployment source config-zip `
    --resource-group $ResourceGroup `
    --name $AppServiceName `
    --src "deploy.zip"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your website is now live at:" -ForegroundColor Cyan
Write-Host "  https://$AppServiceName.azurewebsites.net" -ForegroundColor White
Write-Host ""
Write-Host "API Endpoints:" -ForegroundColor Yellow
Write-Host "  Health Check: https://$AppServiceName.azurewebsites.net/api/health" -ForegroundColor White
Write-Host "  Products: https://$AppServiceName.azurewebsites.net/api/shop/products/get" -ForegroundColor White
Write-Host "  Auth: https://$AppServiceName.azurewebsites.net/api/auth" -ForegroundColor White
Write-Host ""
Write-Host "Azure Storage:" -ForegroundColor Yellow
Write-Host "  Product Images: https://$StorageAccountName.blob.core.windows.net/product-images" -ForegroundColor White
Write-Host "  User Uploads: https://$StorageAccountName.blob.core.windows.net/user-uploads" -ForegroundColor White
Write-Host ""
Write-Host "Monitor logs with:" -ForegroundColor Yellow
Write-Host "  az webapp log tail --name $AppServiceName --resource-group $ResourceGroup" -ForegroundColor Gray
Write-Host ""
Write-Host "View in Azure Portal:" -ForegroundColor Yellow
Write-Host "  https://portal.azure.com" -ForegroundColor Gray
Write-Host ""

# Clean up temporary files
Write-Host "Cleaning up..." -ForegroundColor Gray
Remove-Item "deploy-package" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "deploy.zip" -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[SUCCESS] All done!" -ForegroundColor Green
Write-Host ""
