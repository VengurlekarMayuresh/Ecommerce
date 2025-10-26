# E-Commerce Application - Azure Deployment Documentation

## ✅ Project Overview

Full-stack e-commerce application deployed on Microsoft Azure using:
- **Frontend**: React + Vite
- **Backend**: Node.js + Express
- **Database**: Azure Cosmos DB (MongoDB API)
- **Storage**: Azure Blob Storage
- **Security**: Azure Key Vault
- **Hosting**: Azure App Service

---

## 🏗️ Azure Infrastructure

### Resources Created

| Service | Resource Name | Purpose |
|---------|---------------|---------|
| **App Service** | `ecomm-app-4379` | Web hosting (Node.js 20) |
| **Cosmos DB** | `ecomm-cosmos-4379` | MongoDB-compatible database |
| **Blob Storage** | `ecommstore4379` | Image storage (product-images, user-uploads) |
| **Key Vault** | `ecomm-kv-4379` | Secure secrets management |
| **Resource Group** | `ecommerce-full-rg` | Container for all resources |

### Region
- **Location**: East Asia

---

## 🌐 URLs and Endpoints

### Main Application
```
Website: https://ecomm-app-4379.azurewebsites.net
Health Check: https://ecomm-app-4379.azurewebsites.net/api/health
```

### API Endpoints
```
Auth: /api/auth
  - POST /register
  - POST /login
  - POST /logout
  - GET /check-auth

Admin Products: /api/admin/products
  - POST /upload-image
  - POST /add
  - PUT /edit/:id
  - DELETE /delete/:id
  - GET /get

Admin Orders: /api/admin/orders
  - GET /get
  - GET /details/:id
  - PUT /update/:id

Shop Products: /api/shop/products
  - GET /get
  - GET /get/:id

Cart: /api/shop/cart
  - POST /add
  - GET /get/:userId
  - PUT /update-cart
  - DELETE /:userId/:productId

Address: /api/shop/address
  - POST /add
  - GET /get/:userId
  - PUT /update/:userId/:addressId
  - DELETE /delete/:userId/:addressId

Orders: /api/shop/order
  - POST /create
  - POST /capture
  - GET /list/:userId
  - GET /details/:id

Search: /api/shop/search
  - GET /:keyword

Reviews: /api/shop/review
  - POST /add
  - GET /:productId

Features: /api/common/feature
  - POST /add
  - GET /get
```

### Azure Storage
```
Product Images: https://ecommstore4379.blob.core.windows.net/product-images
User Uploads: https://ecommstore4379.blob.core.windows.net/user-uploads
```

---

## 🔐 Environment Variables

### Configured in Azure App Service

```bash
MONGO_DBURL=mongodb://ecomm-cosmos-4379:...@ecomm-cosmos-4379.mongo.cosmos.azure.com:10255/?ssl=true
CLIENT_URL=https://ecomm-app-4379.azurewebsites.net
PORT=8080
NODE_ENV=production
KEY_VAULT_NAME=ecomm-kv-4379
```

### Stored in Azure Key Vault

- `MONGO-URI` - Cosmos DB connection string
- `JWT-SECRET` - JWT token secret
- `AZURE-STORAGE-CONNECTION-STRING` - Blob storage access
- `AZURE-STORAGE-ACCOUNT-NAME` - ecommstore4379
- `AZURE-STORAGE-ACCOUNT-KEY` - Storage access key

---

## 📁 Project Structure

```
E-commerce/
├── client/                    # React frontend
│   ├── src/
│   ├── dist/                  # Built frontend (after npm run build)
│   ├── package.json
│   └── vite.config.js
│
├── server/                    # Node.js backend
│   ├── config/
│   │   ├── azure-storage.js   # Blob Storage integration
│   │   ├── azure-keyvault.js  # Key Vault integration
│   │   └── azure-*.js         # Other Azure services
│   ├── controllers/
│   ├── models/
│   ├── routes/
│   ├── middleware/
│   ├── helpers/
│   ├── server.js              # Main entry point
│   └── package.json
│
├── FINAL_DEPLOY.ps1           # Deployment script
├── DEPLOYMENT_COMPLETE.md     # This file
└── AZURE_SETUP_COMPLETE.md    # Azure infrastructure docs
```

---

## 🚀 Deployment Instructions

### Prerequisites
- Azure CLI installed and logged in
- Node.js 18+ installed
- npm installed

### Option 1: Automated Deployment (Recommended)

```powershell
# From project root
.\FINAL_DEPLOY.ps1
```

This script will:
1. Verify Azure configuration
2. Clean up old deployments
3. Create deployment package (without node_modules and .env)
4. Create ZIP archive
5. Deploy to Azure App Service

### Option 2: Manual Deployment

```powershell
# 1. Build frontend
cd client
npm install
npm run build

# 2. Prepare server
cd ../server
npm install --production

# 3. Create deployment ZIP
cd ..
Compress-Archive -Path server\* -DestinationPath server-deploy.zip

# 4. Deploy to Azure
az webapp deploy --resource-group ecommerce-full-rg --name ecomm-app-4379 --src-path server-deploy.zip --type zip
```

---

## 🔧 Configuration Management

### Update Environment Variables

Via Azure Portal:
1. Go to https://portal.azure.com
2. Navigate to App Service → `ecomm-app-4379`
3. Configuration → Application settings
4. Add/Edit settings
5. Click Save and Restart

Via Azure CLI:
```powershell
az webapp config appsettings set --name ecomm-app-4379 --resource-group ecommerce-full-rg --settings "KEY=value"
```

### Access Key Vault Secrets

```powershell
# List all secrets
az keyvault secret list --vault-name ecomm-kv-4379 --output table

# Get a specific secret
az keyvault secret show --vault-name ecomm-kv-4379 --name "MONGO-URI" --query value -o tsv

# Set a secret
az keyvault secret set --vault-name ecomm-kv-4379 --name "SECRET-NAME" --value "SECRET-VALUE"
```

---

## 🐛 Troubleshooting

### App Not Starting (503 Error)

1. **Check logs:**
   ```powershell
   az webapp log tail --name ecomm-app-4379 --resource-group ecommerce-full-rg
   ```

2. **Verify environment variables:**
   ```powershell
   az webapp config appsettings list --name ecomm-app-4379 --resource-group ecommerce-full-rg
   ```

3. **Check app status:**
   ```powershell
   az webapp show --name ecomm-app-4379 --resource-group ecommerce-full-rg --query state
   ```

4. **Restart the app:**
   ```powershell
   az webapp restart --name ecomm-app-4379 --resource-group ecommerce-full-rg
   ```

### Database Connection Issues

- Verify Cosmos DB firewall allows App Service IPs
- Check MONGO_DBURL is properly configured
- Ensure managed identity has access to Key Vault

### Blob Storage Not Working

- Verify AZURE_STORAGE_CONNECTION_STRING is set
- Check blob containers exist (product-images, user-uploads)
- Ensure containers have proper access level (blob)

### Key Vault Access Denied

Grant App Service managed identity access:
```powershell
$principalId = az webapp identity show --name ecomm-app-4379 --resource-group ecommerce-full-rg --query principalId -o tsv
az role assignment create --role "Key Vault Secrets User" --assignee $principalId --scope "/subscriptions/266f9e55-2ba1-43eb-9cc4-bf2944999382/resourceGroups/ecommerce-full-rg/providers/Microsoft.KeyVault/vaults/ecomm-kv-4379"
```

---

## 📊 Monitoring and Logs

### View Real-time Logs
```powershell
az webapp log tail --name ecomm-app-4379 --resource-group ecommerce-full-rg
```

### Download Logs
```powershell
az webapp log download --name ecomm-app-4379 --resource-group ecommerce-full-rg --log-file logs.zip
```

### Check App Metrics
- Go to Azure Portal → App Service → `ecomm-app-4379` → Monitoring → Metrics

---

## 💰 Cost Estimation

### Monthly Costs (Approximate)

| Service | Plan | Cost |
|---------|------|------|
| App Service | Basic B1 | ~$13/month |
| Cosmos DB | Free Tier (400 RU/s) | FREE |
| Blob Storage | Standard | ~$0.02/GB + operations |
| Key Vault | Standard | ~$0.03 per 10k operations |
| **Total** | | **~$13-15/month** |

### Cost Optimization Tips
- Cosmos DB has free tier (1000 RU/s, 25GB) - already using
- Use Azure for Students credits
- Stop App Service when not in use (for development)
- Monitor storage usage

---

## 🔒 Security Best Practices

✅ **Implemented:**
- All secrets stored in Azure Key Vault
- Managed Identity for service-to-service authentication
- HTTPS enforced on App Service
- CORS configured
- Environment variables not in code

⚠️ **Additional Recommendations:**
- Enable Application Insights for monitoring
- Set up Azure Front Door for CDN
- Configure custom domain with SSL
- Enable Azure DDoS Protection
- Implement rate limiting

---

## 📚 Additional Resources

- [Azure App Service Docs](https://docs.microsoft.com/azure/app-service/)
- [Cosmos DB MongoDB API](https://docs.microsoft.com/azure/cosmos-db/mongodb/)
- [Azure Blob Storage](https://docs.microsoft.com/azure/storage/blobs/)
- [Azure Key Vault](https://docs.microsoft.com/azure/key-vault/)

---

## ✅ Deployment Checklist

- [x] Azure resources created
- [x] Cosmos DB configured
- [x] Blob Storage ready with containers
- [x] Key Vault setup with secrets
- [x] App Service configured
- [x] Managed Identity enabled
- [x] Environment variables configured
- [x] Frontend built successfully
- [x] Backend has health endpoint
- [x] Code deployed to Azure
- [ ] Application tested end-to-end
- [ ] Custom domain configured (optional)
- [ ] SSL certificate installed (optional)

---

## 🎯 Next Steps

1. **Deploy the latest code:**
   ```powershell
   .\FINAL_DEPLOY.ps1
   ```

2. **Wait 3-5 minutes for deployment**

3. **Test the application:**
   ```powershell
   curl https://ecomm-app-4379.azurewebsites.net/api/health
   ```

4. **Access your website:**
   ```
   https://ecomm-app-4379.azurewebsites.net
   ```

---

## 📞 Support

For issues:
1. Check logs: `az webapp log tail --name ecomm-app-4379 --resource-group ecommerce-full-rg`
2. Verify configuration in Azure Portal
3. Review this documentation

---

**Deployment Date**: October 26, 2025
**Azure Subscription**: Azure for Students
**Region**: East Asia
