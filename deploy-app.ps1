# Deploy Application to Azure Web App
# This script builds and deploys the combined frontend+backend

param(
    [Parameter(Mandatory=$false)]
    [string]$AppServiceName,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "ecommerce-app-rg"
)

Write-Host "[*] Deploying E-Commerce Application to Azure" -ForegroundColor Cyan
Write-Host ""

# Check if deployment-info.txt exists
if (Test-Path "deployment-info.txt") {
    $deployInfo = Get-Content "deployment-info.txt" -Raw
    if ($deployInfo -match "App Service Name: (.+)") {
        $AppServiceName = $matches[1].Trim()
    }
}

if ([string]::IsNullOrWhiteSpace($AppServiceName)) {
    $AppServiceName = Read-Host "Enter App Service Name"
}

Write-Host "App Service: $AppServiceName" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Yellow
Write-Host ""

# Step 1: Build Frontend
Write-Host "[1/4] Building Frontend..." -ForegroundColor Cyan
Set-Location client
npm install
npm run build
Set-Location ..

# Step 2: Prepare Backend
Write-Host "[2/4] Preparing Backend..." -ForegroundColor Cyan
Set-Location server
npm install --production

# Step 3: Create deployment package
Write-Host "[3/4] Creating deployment package..." -ForegroundColor Cyan
Set-Location ..

# Create deploy directory
if (Test-Path "deploy-package") {
    Remove-Item "deploy-package" -Recurse -Force
}
New-Item -ItemType Directory -Path "deploy-package" | Out-Null

# Copy server files
Copy-Item -Path "server\*" -Destination "deploy-package\" -Recurse -Exclude "node_modules"

# Copy built frontend to server's public directory
New-Item -ItemType Directory -Path "deploy-package\public" -Force | Out-Null
Copy-Item -Path "client\dist\*" -Destination "deploy-package\public\" -Recurse

# Create or update server.js to serve frontend
$serverContent = @"
const express = require('express');
const path = require('path');
const cors = require('cors');
const cookieParser = require('cookie-parser');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(cookieParser());

// API Routes (your existing routes)
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

// All other routes serve React app
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Database connection
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/ecommerce')
    .then(() => console.log('MongoDB connected'))
    .catch(err => console.error('MongoDB connection error:', err));

app.listen(PORT, () => {
    console.log(\`Server running on port \${PORT}\`);
});
"@

$serverContent | Out-File -FilePath "deploy-package\server-combined.js" -Encoding UTF8

# Create package.json for deployment
$packageJson = @"
{
  "name": "ecommerce-app",
  "version": "1.0.0",
  "description": "E-commerce application",
  "main": "server-combined.js",
  "scripts": {
    "start": "node server-combined.js"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
"@

$packageJson | Out-File -FilePath "deploy-package\package.json" -Encoding UTF8

# Copy original package.json dependencies
if (Test-Path "server\package.json") {
    $originalPkg = Get-Content "server\package.json" -Raw | ConvertFrom-Json
    $deployPkg = Get-Content "deploy-package\package.json" -Raw | ConvertFrom-Json
    $deployPkg | Add-Member -MemberType NoteProperty -Name "dependencies" -Value $originalPkg.dependencies -Force
    $deployPkg | ConvertTo-Json -Depth 10 | Out-File -FilePath "deploy-package\package.json" -Encoding UTF8
}

# Create .deployment file
@"
[config]
SCM_DO_BUILD_DURING_DEPLOYMENT=true
"@ | Out-File -FilePath "deploy-package\.deployment" -Encoding UTF8

# Create web.config for Azure
@"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <add name="iisnode" path="server-combined.js" verb="*" modules="iisnode"/>
    </handlers>
    <rewrite>
      <rules>
        <rule name="NodeInspector" patternSyntax="ECMAScript" stopProcessing="true">
          <match url="^server-combined.js\/debug[\/]?" />
        </rule>
        <rule name="StaticContent">
          <action type="Rewrite" url="public{REQUEST_URI}"/>
        </rule>
        <rule name="DynamicContent">
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="True"/>
          </conditions>
          <action type="Rewrite" url="server-combined.js"/>
        </rule>
      </rules>
    </rewrite>
    <security>
      <requestFiltering>
        <hiddenSegments>
          <remove segment="bin"/>
        </hiddenSegments>
      </requestFiltering>
    </security>
    <httpErrors existingResponse="PassThrough" />
  </system.webServer>
</configuration>
"@ | Out-File -FilePath "deploy-package\web.config" -Encoding UTF8

# Create zip file
Write-Host "[*] Creating ZIP archive..." -ForegroundColor Cyan
if (Test-Path "deploy.zip") {
    Remove-Item "deploy.zip" -Force
}

Compress-Archive -Path "deploy-package\*" -DestinationPath "deploy.zip" -Force

# Step 4: Deploy to Azure
Write-Host "[4/4] Deploying to Azure..." -ForegroundColor Cyan
az webapp deployment source config-zip `
    --resource-group $ResourceGroup `
    --name $AppServiceName `
    --src "deploy.zip"

Write-Host ""
Write-Host "[SUCCESS] Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Your application is now live at:" -ForegroundColor Cyan
Write-Host "  https://$AppServiceName.azurewebsites.net" -ForegroundColor White
Write-Host ""
Write-Host "Monitor logs with:" -ForegroundColor Yellow
Write-Host "  az webapp log tail --name $AppServiceName --resource-group $ResourceGroup" -ForegroundColor Gray
Write-Host ""
Write-Host "View in Azure Portal:" -ForegroundColor Yellow
Write-Host "  https://portal.azure.com" -ForegroundColor Gray
Write-Host ""

# Clean up
Write-Host "[*] Cleaning up temporary files..." -ForegroundColor Cyan
Remove-Item "deploy-package" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "deploy.zip" -Force -ErrorAction SilentlyContinue

Write-Host "[*] Done!" -ForegroundColor Green
