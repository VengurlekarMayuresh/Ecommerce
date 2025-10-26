# Azure E-commerce Deployment Guide

This guide will help you deploy your E-commerce application to Azure using maximum Azure services.

## 🏗️ Architecture Overview

**Frontend**: Azure Static Web Apps (React + Vite)  
**Backend**: Azure App Service (Node.js + Express)  
**Database**: MongoDB Atlas or Azure Cosmos DB  
**Storage**: Azure Blob Storage (Product Images)  
**Monitoring**: Azure Application Insights  
**Secrets**: Azure Key Vault (Optional)  
**CDN**: Azure CDN (Optional)  

---

## 📋 Prerequisites

1. **Azure Account** - [Create free account](https://azure.microsoft.com/free/)
2. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
3. **GitHub Account** - For CI/CD workflows
4. **Node.js 18+** - For local testing

---

## 🚀 Step-by-Step Deployment

### 1. Azure CLI Login

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Create Resource Group

```bash
az group create --name ecommerce-rg --location eastus
```

### 3. Create Azure Storage Account

```bash
# Create storage account
az storage account create \
  --name ecommstore$(date +%s) \
  --resource-group ecommerce-rg \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot

# Get connection string
az storage account show-connection-string \
  --name ecommstoreXXXXXX \
  --resource-group ecommerce-rg \
  --output tsv

# Create container for product images
az storage container create \
  --name product-images \
  --account-name ecommstoreXXXXXX \
  --public-access blob
```

### 4. Create Application Insights

```bash
# Create App Insights
az monitor app-insights component create \
  --app ecommerce-insights \
  --resource-group ecommerce-rg \
  --location eastus \
  --application-type web

# Get connection string
az monitor app-insights component show \
  --app ecommerce-insights \
  --resource-group ecommerce-rg \
  --query connectionString -o tsv
```

### 5. Create Azure App Service (Backend API)

```bash
# Create App Service Plan
az appservice plan create \
  --name ecommerce-plan \
  --resource-group ecommerce-rg \
  --location eastus \
  --sku B1 \
  --is-linux

# Create Web App
az webapp create \
  --name ecomm-api \
  --resource-group ecommerce-rg \
  --plan ecommerce-plan \
  --runtime "NODE:20-lts"

# Configure app settings
az webapp config appsettings set \
  --name ecomm-api \
  --resource-group ecommerce-rg \
  --settings \
    NODE_ENV=production \
    PORT=8080 \
    MONGO_DBURL="YOUR_MONGODB_CONNECTION_STRING" \
    SECRET_KEY="YOUR_JWT_SECRET" \
    AZURE_STORAGE_CONNECTION_STRING="YOUR_STORAGE_CONNECTION_STRING" \
    APPLICATIONINSIGHTS_CONNECTION_STRING="YOUR_APP_INSIGHTS_CONNECTION_STRING" \
    CLIENT_URL="https://YOUR_STATIC_WEB_APP_URL"

# Enable logging
az webapp log config \
  --name ecomm-api \
  --resource-group ecommerce-rg \
  --application-logging filesystem \
  --web-server-logging filesystem

# Get publish profile for GitHub Actions
az webapp deployment list-publishing-profiles \
  --name ecomm-api \
  --resource-group ecommerce-rg \
  --xml
```

### 6. Create Azure Static Web App (Frontend)

```bash
# Create Static Web App
az staticwebapp create \
  --name ecommerce-frontend \
  --resource-group ecommerce-rg \
  --location eastus2 \
  --source https://github.com/YOUR_USERNAME/YOUR_REPO \
  --branch main \
  --app-location "/client" \
  --output-location "dist" \
  --login-with-github

# Get deployment token
az staticwebapp secrets list \
  --name ecommerce-frontend \
  --resource-group ecommerce-rg \
  --query properties.apiKey -o tsv
```

### 7. (Optional) Create Azure Key Vault

```bash
# Create Key Vault
az keyvault create \
  --name ecommerce-kv \
  --resource-group ecommerce-rg \
  --location eastus

# Add secrets
az keyvault secret set --vault-name ecommerce-kv --name "MONGO-URI" --value "YOUR_VALUE"
az keyvault secret set --vault-name ecommerce-kv --name "JWT-SECRET-KEY" --value "YOUR_VALUE"
az keyvault secret set --vault-name ecommerce-kv --name "PAYPAL-CLIENT-ID" --value "YOUR_VALUE"

# Grant access to App Service
az keyvault set-policy \
  --name ecommerce-kv \
  --object-id $(az webapp identity show --name ecomm-api --resource-group ecommerce-rg --query principalId -o tsv) \
  --secret-permissions get list
```

### 8. (Optional) Create Azure Cosmos DB for MongoDB API

```bash
# Create Cosmos DB account with MongoDB API
az cosmosdb create \
  --name ecommerce-cosmos \
  --resource-group ecommerce-rg \
  --kind MongoDB \
  --server-version 4.2 \
  --default-consistency-level Session \
  --locations regionName=eastus failoverPriority=0 isZoneRedundant=False

# Create database
az cosmosdb mongodb database create \
  --account-name ecommerce-cosmos \
  --resource-group ecommerce-rg \
  --name ecommerce

# Get connection string
az cosmosdb keys list \
  --name ecommerce-cosmos \
  --resource-group ecommerce-rg \
  --type connection-strings
```

---

## 🔧 GitHub Actions Setup

### 1. Add GitHub Secrets

Go to your repository → Settings → Secrets and variables → Actions

Add these secrets:

- `AZURE_WEBAPP_PUBLISH_PROFILE` - From step 5 (App Service)
- `AZURE_STATIC_WEB_APPS_API_TOKEN` - From step 6 (Static Web App)

### 2. Push Code to GitHub

```bash
# Initialize git (if not already)
git init

# Add all files
git add .

# Commit
git commit -m "Azure deployment ready"

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push to main branch
git branch -M main
git push -u origin main
```

### 3. Workflows will automatically trigger and deploy!

---

## 🔐 Environment Variables Configuration

### Backend (Azure App Service)

Set these in Azure Portal → App Service → Configuration → Application Settings:

```
NODE_ENV=production
PORT=8080
MONGO_DBURL=<your-mongodb-connection-string>
SECRET_KEY=<your-jwt-secret>
AZURE_STORAGE_CONNECTION_STRING=<your-storage-connection>
APPLICATIONINSIGHTS_CONNECTION_STRING=<your-app-insights-connection>
CLIENT_URL=https://<your-static-web-app>.azurestaticapps.net
CLOUDINARY_CLOUD_NAME=<your-cloudinary-name>
CLOUDINARY_API_KEY=<your-cloudinary-key>
CLOUDINARY_API_SECRET=<your-cloudinary-secret>
PAYPAL_CLIENT_ID=<your-paypal-client-id>
PAYPAL_CLIENT_SECRET=<your-paypal-secret>
PAYPAL_MODE=sandbox
```

### Frontend (Azure Static Web App)

Create `.env.production` in client folder:

```
VITE_API_URL=https://ecomm-api.azurewebsites.net/api
VITE_APP_NAME=E-commerce Store
```

---

## 📊 Monitoring & Troubleshooting

### View Application Insights

```bash
az monitor app-insights metrics show \
  --app ecommerce-insights \
  --resource-group ecommerce-rg \
  --metric requests/count
```

### View App Service Logs

```bash
az webapp log tail \
  --name ecomm-api \
  --resource-group ecommerce-rg
```

### Test Endpoints

```bash
# Backend health check
curl https://ecomm-api.azurewebsites.net/api/health

# Frontend
curl https://YOUR_STATIC_WEB_APP.azurestaticapps.net
```

---

## 🎯 Quick Deploy Script

Save this as `deploy-azure.sh`:

```bash
#!/bin/bash

# Variables
RESOURCE_GROUP="ecommerce-rg"
LOCATION="eastus"
APP_NAME="ecomm-api"
STATIC_APP_NAME="ecommerce-frontend"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Deploy backend
cd server
zip -r ../deploy.zip .
az webapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --src ../deploy.zip

# Deploy frontend
cd ../client
npm run build
az staticwebapp upload \
  --name $STATIC_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --source ./dist

echo "✅ Deployment complete!"
```

Run it:
```bash
chmod +x deploy-azure.sh
./deploy-azure.sh
```

---

## 🌐 Custom Domain Setup (Optional)

### Backend Custom Domain

```bash
az webapp config hostname add \
  --webapp-name ecomm-api \
  --resource-group ecommerce-rg \
  --hostname api.yourdomain.com
```

### Frontend Custom Domain

```bash
az staticwebapp hostname set \
  --name ecommerce-frontend \
  --resource-group ecommerce-rg \
  --hostname www.yourdomain.com
```

---

## 💰 Cost Optimization Tips

1. **App Service**: Use B1 tier for dev, scale to P1V2 for production
2. **Static Web Apps**: Free tier includes 100GB bandwidth
3. **Storage**: Use Hot tier for frequently accessed images
4. **Cosmos DB**: Use serverless mode for lower costs
5. **Application Insights**: Set sampling to 50% in production

---

## 🆘 Common Issues & Solutions

### Issue: App Service deployment fails
**Solution**: Check logs with `az webapp log tail`

### Issue: Static Web App build fails
**Solution**: Verify `output_location` in workflow matches Vite build output (`dist`)

### Issue: CORS errors
**Solution**: Update `CLIENT_URL` environment variable in App Service

### Issue: Images not loading
**Solution**: Verify blob storage container has public access

---

## 📞 Support Resources

- [Azure Documentation](https://docs.microsoft.com/azure/)
- [Azure Support](https://azure.microsoft.com/support/)
- [GitHub Actions Docs](https://docs.github.com/actions)

---

## ✅ Deployment Checklist

- [ ] Azure account created
- [ ] Resource group created
- [ ] Storage account configured
- [ ] Application Insights enabled
- [ ] App Service created and configured
- [ ] Static Web App created
- [ ] Environment variables set
- [ ] GitHub secrets configured
- [ ] Code pushed to GitHub
- [ ] Workflows triggered successfully
- [ ] Health checks passing
- [ ] Frontend accessible
- [ ] Backend API responding

---

**Need Help?** Contact Azure support or check Application Insights for detailed error logs.
