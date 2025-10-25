# Azure Deployment Guide for E-Commerce Platform

This guide covers deploying your full-stack e-commerce application to Azure using multiple Azure services for maximum cloud integration.

## 🏗️ Azure Services Architecture

### Services Used:
1. **Azure Static Web Apps** - React/Vite Frontend
2. **Azure App Service** - Node.js/Express Backend API
3. **Azure Cosmos DB for MongoDB API** - Database
4. **Azure Key Vault** - Secrets Management
5. **Azure Blob Storage** - Image Storage (Alternative to Cloudinary)
6. **Azure Application Insights** - Monitoring & Analytics
7. **Azure CDN** - Content Delivery Network
8. **Azure Front Door** (Optional) - Global Load Balancing

---

## 📋 Prerequisites

1. **Azure Account**: [Create free account](https://azure.microsoft.com/free/)
2. **Azure CLI**: Install from [here](https://docs.microsoft.com/cli/azure/install-azure-cli)
3. **GitHub Account**: For CI/CD pipelines
4. **Node.js 18+**: Required for local development

---

## 🚀 Step-by-Step Deployment

### 1. Azure Cosmos DB Setup (MongoDB API)

#### Create Cosmos DB Account:
```bash
# Login to Azure
az login

# Set variables
RESOURCE_GROUP="ecommerce-rg"
LOCATION="eastus"
COSMOS_ACCOUNT_NAME="ecommerce-cosmos-db"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Cosmos DB account with MongoDB API
az cosmosdb create \
  --name $COSMOS_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --kind MongoDB \
  --server-version 4.2 \
  --default-consistency-level Session \
  --locations regionName=$LOCATION failoverPriority=0 isZoneRedundant=False

# Get connection string
az cosmosdb keys list \
  --name $COSMOS_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --type connection-strings \
  --query "connectionStrings[0].connectionString" -o tsv
```

**Note**: Save the connection string - you'll need it for Key Vault.

#### Migration from MongoDB:
```bash
# Export from current MongoDB
mongodump --uri="mongodb://localhost:27017/ecommerce" --out=./backup

# Import to Cosmos DB
mongorestore --uri="<COSMOS_DB_CONNECTION_STRING>" --db=ecommerce ./backup/ecommerce
```

---

### 2. Azure Key Vault Setup

```bash
KEY_VAULT_NAME="ecommerce-keyvault"

# Create Key Vault
az keyvault create \
  --name $KEY_VAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Add secrets
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "MONGO-URI" --value "<YOUR_COSMOS_DB_CONNECTION_STRING>"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "JWT-SECRET-KEY" --value "<YOUR_JWT_SECRET>"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "CLOUDINARY-CLOUD-NAME" --value "<YOUR_CLOUDINARY_NAME>"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "CLOUDINARY-API-KEY" --value "<YOUR_CLOUDINARY_KEY>"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "CLOUDINARY-API-SECRET" --value "<YOUR_CLOUDINARY_SECRET>"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "PAYPAL-CLIENT-ID" --value "<YOUR_PAYPAL_CLIENT_ID>"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "PAYPAL-CLIENT-SECRET" --value "<YOUR_PAYPAL_SECRET>"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "PAYPAL-MODE" --value "sandbox"
```

---

### 3. Azure Blob Storage Setup (Optional - Alternative to Cloudinary)

```bash
STORAGE_ACCOUNT_NAME="ecommercestorage"

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2

# Create container for product images
az storage container create \
  --name product-images \
  --account-name $STORAGE_ACCOUNT_NAME \
  --public-access blob

# Get connection string
az storage account show-connection-string \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query connectionString -o tsv

# Add to Key Vault
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "AZURE-STORAGE-CONNECTION-STRING" --value "<CONNECTION_STRING>"
```

---

### 4. Azure App Service (Backend API)

```bash
APP_SERVICE_NAME="ecommerce-api"
APP_SERVICE_PLAN="ecommerce-plan"

# Create App Service Plan (Linux)
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --is-linux \
  --sku B1

# Create Web App
az webapp create \
  --name $APP_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime "NODE:18-lts"

# Configure environment variables
az webapp config appsettings set \
  --name $APP_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings \
    KEY_VAULT_NAME=$KEY_VAULT_NAME \
    NODE_ENV=production \
    PORT=8080

# Enable system-assigned managed identity
az webapp identity assign \
  --name $APP_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP

# Get the managed identity principal ID
PRINCIPAL_ID=$(az webapp identity show \
  --name $APP_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query principalId -o tsv)

# Grant Key Vault access to the managed identity
az keyvault set-policy \
  --name $KEY_VAULT_NAME \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list

# Get publish profile for GitHub Actions
az webapp deployment list-publishing-profiles \
  --name $APP_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --xml
```

**Note**: Copy the publish profile XML for GitHub secrets.

#### Update Backend Dependencies:
```bash
cd server
npm install @azure/identity @azure/keyvault-secrets @azure/storage-blob applicationinsights --save
```

---

### 5. Azure Application Insights

```bash
APPINSIGHTS_NAME="ecommerce-insights"

# Create Application Insights
az monitor app-insights component create \
  --app $APPINSIGHTS_NAME \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --application-type web

# Get connection string
APPINSIGHTS_CONNECTION_STRING=$(az monitor app-insights component show \
  --app $APPINSIGHTS_NAME \
  --resource-group $RESOURCE_GROUP \
  --query connectionString -o tsv)

# Add to App Service
az webapp config appsettings set \
  --name $APP_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING=$APPINSIGHTS_CONNECTION_STRING
```

---

### 6. Azure Static Web Apps (Frontend)

#### Via Azure Portal:
1. Go to [Azure Portal](https://portal.azure.com)
2. Create **Static Web App**
3. Connect to your GitHub repository
4. Select:
   - **App location**: `/client`
   - **Output location**: `dist`
   - **Build preset**: `React`
5. Azure will create GitHub Actions workflow automatically

#### Via Azure CLI:
```bash
STATIC_WEB_APP_NAME="ecommerce-frontend"

# Create Static Web App
az staticwebapp create \
  --name $STATIC_WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Free

# Get deployment token
az staticwebapp secrets list \
  --name $STATIC_WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "properties.apiKey" -o tsv
```

#### Configure Frontend Environment:
Update `client/.env.production`:
```env
VITE_API_URL=https://ecommerce-api.azurewebsites.net
VITE_APPINSIGHTS_CONNECTION_STRING=<YOUR_CONNECTION_STRING>
```

---

### 7. GitHub Secrets Configuration

Add these secrets to your GitHub repository (`Settings > Secrets and variables > Actions`):

- `AZURE_STATIC_WEB_APPS_API_TOKEN` - From Static Web Apps
- `AZURE_WEBAPP_NAME` - Your App Service name
- `AZURE_WEBAPP_PUBLISH_PROFILE` - Publish profile XML from App Service

---

### 8. CORS Configuration

Update your backend CORS settings to allow Static Web App:
```bash
# Get Static Web App URL
STATIC_WEB_APP_URL=$(az staticwebapp show \
  --name $STATIC_WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "defaultHostname" -o tsv)

echo "Frontend URL: https://$STATIC_WEB_APP_URL"
```

Update `server/server.js` CORS origin:
```javascript
app.use(cors({
  origin: process.env.FRONTEND_URL || "https://<your-static-web-app>.azurestaticapps.net",
  credentials: true
}));
```

Add to App Service settings:
```bash
az webapp config appsettings set \
  --name $APP_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings FRONTEND_URL=https://$STATIC_WEB_APP_URL
```

---

### 9. Azure CDN (Optional - for better performance)

```bash
CDN_PROFILE="ecommerce-cdn"
CDN_ENDPOINT="ecommerce-endpoint"

# Create CDN profile
az cdn profile create \
  --name $CDN_PROFILE \
  --resource-group $RESOURCE_GROUP \
  --sku Standard_Microsoft

# Create CDN endpoint for Static Web App
az cdn endpoint create \
  --name $CDN_ENDPOINT \
  --profile-name $CDN_PROFILE \
  --resource-group $RESOURCE_GROUP \
  --origin $STATIC_WEB_APP_URL \
  --origin-host-header $STATIC_WEB_APP_URL
```

---

## 🔄 Deployment Process

### Automatic Deployment (Recommended):
1. Push to `main` branch
2. GitHub Actions automatically deploy:
   - Frontend to Azure Static Web Apps
   - Backend to Azure App Service

### Manual Deployment:

#### Frontend:
```bash
cd client
npm run build
az staticwebapp deploy --name $STATIC_WEB_APP_NAME --resource-group $RESOURCE_GROUP --app-location ./dist
```

#### Backend:
```bash
cd server
zip -r deploy.zip .
az webapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE_NAME \
  --src deploy.zip
```

---

## 🔍 Monitoring & Debugging

### View Application Insights:
```bash
# Open Application Insights in browser
az monitor app-insights component show \
  --app $APPINSIGHTS_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id -o tsv
```

### View App Service Logs:
```bash
# Stream logs
az webapp log tail --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP

# Download logs
az webapp log download --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP --log-file logs.zip
```

### View Static Web App Logs:
Check GitHub Actions tab in your repository

---

## 💰 Cost Optimization

1. **Free Tier Options:**
   - Static Web Apps: Free tier (100 GB bandwidth/month)
   - Cosmos DB: Free tier (1000 RU/s, 25 GB storage)
   - Key Vault: Pay per operation (very low cost)

2. **Scaling:**
   - App Service: Scale up/down based on load
   - Cosmos DB: Use autoscale for RU/s

3. **Cost Monitoring:**
```bash
# Set up budget alerts
az consumption budget create \
  --budget-name "monthly-budget" \
  --amount 100 \
  --category cost \
  --time-grain monthly \
  --resource-group $RESOURCE_GROUP
```

---

## 🔒 Security Checklist

- ✅ Secrets in Key Vault (not in code)
- ✅ Managed Identity for App Service
- ✅ HTTPS enforced on all services
- ✅ CORS properly configured
- ✅ Network security groups (optional)
- ✅ Private endpoints for Cosmos DB (optional)
- ✅ Azure Front Door with WAF (optional)

---

## 🧪 Testing Production

```bash
# Frontend URL
echo "Frontend: https://$STATIC_WEB_APP_URL"

# Backend URL
echo "Backend: https://$APP_SERVICE_NAME.azurewebsites.net"

# Test API
curl https://$APP_SERVICE_NAME.azurewebsites.net/api/health
```

---

## 📚 Additional Resources

- [Azure Static Web Apps Docs](https://docs.microsoft.com/azure/static-web-apps/)
- [Azure App Service Docs](https://docs.microsoft.com/azure/app-service/)
- [Azure Cosmos DB Docs](https://docs.microsoft.com/azure/cosmos-db/)
- [Azure Key Vault Docs](https://docs.microsoft.com/azure/key-vault/)
- [Application Insights Docs](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)

---

## 🆘 Troubleshooting

### Common Issues:

1. **Backend can't connect to Cosmos DB:**
   - Verify connection string in Key Vault
   - Check managed identity permissions
   - Enable Cosmos DB firewall rules for App Service IP

2. **Frontend can't call Backend API:**
   - Verify CORS settings
   - Check API URL in frontend .env
   - Ensure App Service is running

3. **Key Vault access denied:**
   - Verify managed identity is enabled
   - Check Key Vault access policies

### Get Help:
```bash
# App Service diagnostics
az webapp browse --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP

# Check service health
az resource list --resource-group $RESOURCE_GROUP --query "[].{Name:name, Status:provisioningState}"
```

---

## 🎯 Next Steps

1. Set up custom domain
2. Enable Azure Front Door for global distribution
3. Configure backup strategy for Cosmos DB
4. Set up staging environments
5. Implement Azure DevOps pipelines (alternative to GitHub Actions)
6. Add Azure Redis Cache for session management
7. Set up Azure Monitor alerts

---

**Deployment Status Dashboard**: Monitor all services from [Azure Portal](https://portal.azure.com)
