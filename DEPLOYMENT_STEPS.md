# 🚀 Complete Azure Deployment - Step-by-Step Guide

This guide walks you through hosting your e-commerce website on Azure from scratch. Follow each step carefully.

---

## ✅ Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Azure Account** - [Sign up for free](https://azure.microsoft.com/free/) ($200 credit)
- [ ] **GitHub Account** - For CI/CD deployment
- [ ] **Azure CLI** - [Download](https://aka.ms/azure-cli)
- [ ] **Git** - [Download](https://git-scm.com/downloads)
- [ ] **Node.js 18+** - [Download](https://nodejs.org/)
- [ ] **PayPal Developer Account** - [Sign up](https://developer.paypal.com/)
- [ ] **Your code pushed to GitHub** - Create a repository

---

## 📋 Phase 1: Initial Setup (15 minutes)

### Step 1.1: Install Azure CLI

```powershell
# Download and install Azure CLI
# Visit: https://aka.ms/azure-cli

# Verify installation
az --version
```

**Expected Output:** Azure CLI version 2.x.x

### Step 1.2: Login to Azure

```powershell
# Login to your Azure account
az login

# If you have multiple subscriptions, set the default
az account list --output table
az account set --subscription "Your-Subscription-Name"
```

### Step 1.3: Push Code to GitHub

```powershell
# Initialize git (if not already done)
cd D:\Users\Radhika\Documents\E-commerce
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit for Azure deployment"

# Create GitHub repository and push
# Go to https://github.com/new to create a repository named "ecommerce-azure"

# Add remote and push
git remote add origin https://github.com/YOUR_USERNAME/ecommerce-azure.git
git branch -M main
git push -u origin main
```

---

## 📋 Phase 2: Prepare Application (10 minutes)

### Step 2.1: Update Backend Dependencies

```powershell
cd server

# Copy the Azure-ready package.json
Copy-Item package-azure-complete.json package.json -Force

# Install all dependencies
npm install

# Verify installation
npm list --depth=0
```

### Step 2.2: Create Production Environment File

Create `server/.env.production`:

```env
# This file is for local testing only
# Production will use Azure Key Vault

NODE_ENV=production
PORT=8080
```

### Step 2.3: Update Frontend for Production

Create `client/.env.production`:

```env
# Update this after deploying backend
VITE_API_URL=https://YOUR_APP_NAME.azurewebsites.net
```

### Step 2.4: Test Locally

```powershell
# Test backend
cd server
npm start

# In another terminal, test frontend
cd client
npm run dev
```

Stop both servers (Ctrl+C) once verified.

---

## 📋 Phase 3: Gather Credentials (10 minutes)

Before deployment, collect these credentials:

### Step 3.1: PayPal Credentials

1. Go to [PayPal Developer](https://developer.paypal.com/)
2. Navigate to **Dashboard** → **My Apps & Credentials**
3. Create a **Sandbox App** (for testing) or use **Live** (for production)
4. Copy:
   - **Client ID**: `AXxxxxxxxxxxxxxxx`
   - **Secret**: `ELxxxxxxxxxxxxxxx`

### Step 3.2: Cloudinary Credentials (Optional)

1. Go to [Cloudinary](https://cloudinary.com/)
2. Sign up/login
3. Copy from Dashboard:
   - **Cloud Name**: `dxxxxxxxx`
   - **API Key**: `123456789012345`
   - **API Secret**: `xxxxxxxxxxxxxxxxx`

**Note:** You can skip Cloudinary and use Azure Blob Storage instead.

### Step 3.3: Save Credentials Securely

Create a temporary file `credentials.txt` (don't commit this!):

```
PAYPAL_CLIENT_ID=AXxxxxxxxxxxxxxxx
PAYPAL_SECRET=ELxxxxxxxxxxxxxxx
PAYPAL_MODE=sandbox

CLOUDINARY_CLOUD_NAME=dxxxxxxxx
CLOUDINARY_API_KEY=123456789012345
CLOUDINARY_API_SECRET=xxxxxxxxxxxxxxxxx
```

---

## 📋 Phase 4: Automated Azure Deployment (20 minutes)

### Step 4.1: Run Deployment Script

```powershell
# Navigate to project root
cd D:\Users\Radhika\Documents\E-commerce

# Run the complete deployment script
.\deploy-azure-complete.ps1
```

### Step 4.2: Follow Prompts

The script will ask for:

1. **PayPal Client ID**: Paste from credentials.txt
2. **PayPal Client Secret**: Paste from credentials.txt
3. **PayPal Mode**: Type `sandbox` (or `live` for production)
4. **Use Cloudinary?**: Type `y` or `n`
   - If `y`, provide Cloudinary credentials
5. **Email sender address**: You'll configure this later, type: `temp@temp.com`
6. **Admin notification email**: Your email address

### Step 4.3: Save Output

The script will output important URLs. **Copy and save these:**

```
Frontend: https://ecommerce-frontend-XXXX.azurestaticapps.net
Backend API: https://ecommerce-api-XXXX.azurewebsites.net
Key Vault: https://ecommerce-kv-XXXX.vault.azure.net
```

**⏱️ This process takes 15-20 minutes. Don't close the terminal!**

---

## 📋 Phase 5: Configure Email Service (10 minutes)

### Step 5.1: Configure Azure Communication Services

1. Go to [Azure Portal](https://portal.azure.com)
2. Search for **Communication Services**
3. Click on your service (ecommerce-comm-XXXX)
4. Navigate to **Email** → **Provision domains**
5. Click **Azure Managed Domain**
6. Click **Add**
7. Wait 2-5 minutes for provisioning
8. Copy the sender email: `DoNotReply@xxxxxxxx.azurecomm.net`

### Step 5.2: Update Key Vault with Email

```powershell
# Set variables (use your actual Key Vault name from Step 4.3)
$KEY_VAULT_NAME="ecommerce-kv-XXXX"
$SENDER_EMAIL="DoNotReply@xxxxxxxx.azurecomm.net"

# Update secret
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "AZURE-COMMUNICATION-SENDER-ADDRESS" --value $SENDER_EMAIL
```

---

## 📋 Phase 6: Configure Push Notifications (Optional, 10 minutes)

### Step 6.1: Setup Firebase Cloud Messaging

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** or select existing
3. Enter project name: `EcommercePushNotifications`
4. Disable Google Analytics (optional)
5. Click **Create project**

### Step 6.2: Get FCM Server Key

1. Click **⚙️ Settings** → **Project settings**
2. Navigate to **Cloud Messaging** tab
3. Copy **Server key**: `AAAAxxxxxxxxxxxxxxxxxxxxxxxx`

### Step 6.3: Add FCM to Notification Hub

```powershell
# Set variables (use your actual names from Step 4.3)
$RESOURCE_GROUP="ecommerce-rg"
$NOTIFICATION_NAMESPACE="ecommerce-notify-XXXX"
$NOTIFICATION_HUB="ecommerce-hub"
$FCM_SERVER_KEY="AAAAxxxxxxxxxxxxxxxxxxxxxxxx"

# Update notification hub
az notification-hub credential gcm update `
  --resource-group $RESOURCE_GROUP `
  --namespace-name $NOTIFICATION_NAMESPACE `
  --notification-hub-name $NOTIFICATION_HUB `
  --google-api-key $FCM_SERVER_KEY
```

---

## 📋 Phase 7: Setup Azure AD B2C (Optional, 15 minutes)

**Note:** Skip this if you want to use your existing authentication system.

### Step 7.1: Create Azure AD B2C Tenant

1. Go to [Azure Portal](https://portal.azure.com)
2. Search **Azure AD B2C**
3. Click **Create**
4. Select **Create a new Azure AD B2C Tenant**
5. Fill in:
   - **Organization name**: EcommerceB2C
   - **Initial domain**: ecommerceb2c (must be unique)
   - **Country**: United States
6. Click **Review + Create** → **Create**

**⏱️ This takes 5-10 minutes.**

### Step 7.2: Register Application

1. Go to your new B2C tenant
2. **App registrations** → **New registration**
3. Settings:
   - **Name**: Ecommerce-API
   - **Supported accounts**: Accounts in any identity provider
   - **Redirect URI**: Leave blank for now
4. Click **Register**
5. Copy **Application (client) ID**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

### Step 7.3: Create Client Secret

1. **Certificates & secrets** → **New client secret**
2. **Description**: API-Secret
3. **Expires**: 24 months
4. Click **Add**
5. **Copy the Value immediately** (you won't see it again!)

### Step 7.4: Add to Key Vault

```powershell
$KEY_VAULT_NAME="ecommerce-kv-XXXX"
$B2C_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$B2C_CLIENT_SECRET="your-secret-value"
$B2C_AUTHORITY="https://ecommerceb2c.b2clogin.com/ecommerceb2c.onmicrosoft.com/B2C_1_signupsignin"

az keyvault secret set --vault-name $KEY_VAULT_NAME --name "AZURE-AD-B2C-CLIENT-ID" --value $B2C_CLIENT_ID
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "AZURE-AD-B2C-CLIENT-SECRET" --value $B2C_CLIENT_SECRET
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "AZURE-AD-B2C-AUTHORITY" --value $B2C_AUTHORITY
```

---

## 📋 Phase 8: Setup GitHub Actions CI/CD (15 minutes)

### Step 8.1: Get Static Web Apps Deployment Token

```powershell
$RESOURCE_GROUP="ecommerce-rg"
$STATIC_WEB_APP_NAME="ecommerce-frontend-XXXX"

# Get deployment token
$SWA_TOKEN = az staticwebapp secrets list `
  --name $STATIC_WEB_APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --query "properties.apiKey" -o tsv

Write-Host "Static Web App Token: $SWA_TOKEN"
```

**Copy this token!**

### Step 8.2: Get App Service Publish Profile

```powershell
$APP_SERVICE_NAME="ecommerce-api-XXXX"

# Download publish profile
az webapp deployment list-publishing-profiles `
  --name $APP_SERVICE_NAME `
  --resource-group $RESOURCE_GROUP `
  --xml > publish-profile.xml

# Open the file
notepad publish-profile.xml
```

**Copy the entire XML content!**

### Step 8.3: Add GitHub Secrets

1. Go to your GitHub repository
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

Add these secrets:

| Name | Value |
|------|-------|
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | Token from Step 8.1 |
| `AZURE_WEBAPP_NAME` | `ecommerce-api-XXXX` |
| `AZURE_WEBAPP_PUBLISH_PROFILE` | XML from Step 8.2 |

### Step 8.4: Update Frontend Environment Variable

```powershell
# Update client/.env.production with your actual backend URL
$BACKEND_URL="https://ecommerce-api-XXXX.azurewebsites.net"

@"
VITE_API_URL=$BACKEND_URL
"@ | Out-File -FilePath "client\.env.production" -Encoding UTF8
```

### Step 8.5: Commit and Push

```powershell
git add .
git commit -m "Configure Azure deployment"
git push origin main
```

**✨ GitHub Actions will automatically deploy your app!**

---

## 📋 Phase 9: Configure CORS (5 minutes)

### Step 9.1: Update Backend CORS

```powershell
$APP_SERVICE_NAME="ecommerce-api-XXXX"
$STATIC_WEB_APP_URL="https://ecommerce-frontend-XXXX.azurestaticapps.net"

# Add CORS setting
az webapp config appsettings set `
  --name $APP_SERVICE_NAME `
  --resource-group ecommerce-rg `
  --settings FRONTEND_URL=$STATIC_WEB_APP_URL
```

### Step 9.2: Update server.js (if needed)

If your `server/server.js` has hardcoded CORS, update it:

```javascript
app.use(cors({
  origin: process.env.FRONTEND_URL || "http://localhost:5173",
  credentials: true
}));
```

Then commit and push:

```powershell
git add server/server.js
git commit -m "Update CORS for production"
git push origin main
```

---

## 📋 Phase 10: Test Your Deployment (10 minutes)

### Step 10.1: Test Backend API

```powershell
$BACKEND_URL="https://ecommerce-api-XXXX.azurewebsites.net"

# Test health endpoint
curl $BACKEND_URL/api/health
```

**Expected:** Response with status or error (if no health endpoint, try `/api/products`)

### Step 10.2: Test Frontend

1. Open browser
2. Navigate to: `https://ecommerce-frontend-XXXX.azurestaticapps.net`
3. Test:
   - ✅ Homepage loads
   - ✅ Product listing works
   - ✅ Login/Register works
   - ✅ Add to cart
   - ✅ Checkout process

### Step 10.3: Test Notifications (Optional)

Create a test order and check:
- ✅ Email received (check spam folder)
- ✅ Admin email received
- ✅ Push notification sent (if configured)

---

## 📋 Phase 11: Migrate Database (10 minutes)

### Step 11.1: Export Local MongoDB Data

```powershell
# If you have local MongoDB data
mongodump --uri="mongodb://localhost:27017/ecommerce" --out=./backup
```

### Step 11.2: Get Cosmos DB Connection String

```powershell
$COSMOS_ACCOUNT_NAME="ecommerce-cosmos-XXXX"

$COSMOS_URI = az cosmosdb keys list `
  --name $COSMOS_ACCOUNT_NAME `
  --resource-group ecommerce-rg `
  --type connection-strings `
  --query "connectionStrings[0].connectionString" -o tsv

Write-Host "Cosmos DB URI: $COSMOS_URI"
```

### Step 11.3: Import to Cosmos DB

```powershell
# Install mongorestore if not installed
# Download from: https://www.mongodb.com/try/download/database-tools

# Import data
mongorestore --uri="$COSMOS_URI" --db=ecommerce ./backup/ecommerce
```

---

## 📋 Phase 12: Configure Custom Domain (Optional, 20 minutes)

### Step 12.1: Purchase Domain

Purchase from:
- [GoDaddy](https://www.godaddy.com/)
- [Namecheap](https://www.namecheap.com/)
- [Google Domains](https://domains.google/)

### Step 12.2: Configure Static Web App Domain

1. Azure Portal → Your Static Web App
2. **Custom domains** → **Add**
3. Enter: `www.yourdomain.com`
4. Copy the CNAME record
5. Add to your DNS provider:
   - **Type**: CNAME
   - **Name**: www
   - **Value**: (from Azure)
6. Wait 10-60 minutes for propagation

### Step 12.3: Configure App Service Domain

1. Azure Portal → Your App Service
2. **Custom domains** → **Add custom domain**
3. Enter: `api.yourdomain.com`
4. Add CNAME record to DNS

---

## 📋 Phase 13: Final Verification (10 minutes)

### ✅ Final Checklist

- [ ] Frontend loads successfully
- [ ] Backend API responds
- [ ] User registration works
- [ ] User login works
- [ ] Products display correctly
- [ ] Add to cart works
- [ ] Checkout process completes
- [ ] PayPal payment works (in sandbox mode)
- [ ] Email notifications sent
- [ ] Admin panel accessible (if using AD B2C)
- [ ] Images upload successfully
- [ ] Database operations work
- [ ] GitHub Actions deploy successfully

### 📊 Monitor Application

1. **Application Insights**:
   - Azure Portal → Application Insights → ecommerce-insights
   - Check **Live Metrics**

2. **App Service Logs**:
   ```powershell
   az webapp log tail --name ecommerce-api-XXXX --resource-group ecommerce-rg
   ```

3. **Static Web App Logs**:
   - GitHub repository → Actions tab

---

## 🎯 Post-Deployment Tasks

### Security Hardening

- [ ] Enable HTTPS only in App Service
- [ ] Configure firewall rules for Cosmos DB
- [ ] Set up Azure Monitor alerts
- [ ] Enable backup for Cosmos DB
- [ ] Review and rotate secrets

### Performance Optimization

- [ ] Enable CDN for Static Web App
- [ ] Configure caching in App Service
- [ ] Optimize database queries
- [ ] Enable compression

### Monitoring Setup

```powershell
# Create budget alert
az consumption budget create `
  --budget-name "monthly-budget" `
  --amount 50 `
  --category cost `
  --time-grain monthly `
  --resource-group ecommerce-rg
```

---

## 🆘 Troubleshooting

### Issue: Frontend can't connect to Backend

**Solution:**
1. Check CORS settings in App Service
2. Verify `.env.production` has correct API URL
3. Check browser console for errors

```powershell
# View backend logs
az webapp log tail --name ecommerce-api-XXXX --resource-group ecommerce-rg
```

### Issue: Database connection fails

**Solution:**
1. Verify Cosmos DB connection string in Key Vault
2. Check App Service managed identity permissions
3. Enable Cosmos DB firewall for App Service IP

```powershell
# Get App Service IP
az webapp show --name ecommerce-api-XXXX --resource-group ecommerce-rg --query outboundIpAddresses
```

### Issue: GitHub Actions fails

**Solution:**
1. Check secrets are correct
2. Verify publish profile is valid
3. Check Actions logs in GitHub

### Issue: Emails not sending

**Solution:**
1. Verify Communication Services domain is provisioned
2. Check sender email in Key Vault
3. Test with simple email first

---

## 📚 Documentation Links

- [Azure Portal](https://portal.azure.com)
- [Azure Documentation](https://docs.microsoft.com/azure/)
- [Static Web Apps Docs](https://docs.microsoft.com/azure/static-web-apps/)
- [App Service Docs](https://docs.microsoft.com/azure/app-service/)
- [Cosmos DB Docs](https://docs.microsoft.com/azure/cosmos-db/)

---

## 🎉 Congratulations!

Your e-commerce website is now live on Azure with:
- ✅ Global CDN distribution
- ✅ Auto-scaling backend
- ✅ Managed database
- ✅ Email notifications
- ✅ Push notifications
- ✅ Enterprise security
- ✅ CI/CD pipeline
- ✅ Monitoring & analytics

**Your URLs:**
- **Frontend**: https://ecommerce-frontend-XXXX.azurestaticapps.net
- **Backend**: https://ecommerce-api-XXXX.azurewebsites.net

---

**Need help?** Check the troubleshooting section or review:
- `AZURE_DEPLOYMENT.md` - Core services
- `AZURE_IAM_NOTIFICATIONS.md` - IAM & notifications
