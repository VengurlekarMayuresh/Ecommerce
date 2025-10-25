# Environment Variables Configuration

## ✅ Currently Configured in Azure App Service

### Core Settings (via Key Vault)
- `KEY_VAULT_NAME` = ecomm-kv-4379
- `MONGO_DBURL` = @Microsoft.KeyVault (Azure Cosmos DB connection)
- `AZURE_STORAGE_CONNECTION_STRING` = @Microsoft.KeyVault (Blob Storage)
- `SECRET_KEY` = onlinemayuresh29 (⚠️ Should move to Key Vault)

### Application Settings
- `CLIENT_URL` = http://localhost:5173 (Update to your frontend URL)
- `NODE_ENV` = production
- `PORT` = 8080

### Legacy Settings (Can be removed once fully migrated to Azure)
- `CLOUDINARY_CLOUD_NAME` = ds20dwlrs (Not needed with Azure Blob)
- `CLOUDINARY_API_KEY` = 458753332856375 (Not needed with Azure Blob)
- `CLOUDINARY_API_SECRET` = tcqI98ArkHPoSZt2lPsuDQQ5cfs (Not needed with Azure Blob)

## ⚠️ Missing/Optional Settings

### PayPal (Required for payments)
Add these to Azure Portal → App Service → Configuration:
- `PAYPAL_CLIENT_ID` = @Microsoft.KeyVault(SecretUri=https://ecomm-kv-4379.vault.azure.net/secrets/PAYPAL-CLIENT-ID/)
- `PAYPAL_CLIENT_SECRET` = @Microsoft.KeyVault(SecretUri=https://ecomm-kv-4379.vault.azure.net/secrets/PAYPAL-CLIENT-SECRET/)
- `PAYPAL_MODE` = sandbox (or "live" for production)

**To update PayPal in Key Vault:**
```powershell
az keyvault secret set --vault-name ecomm-kv-4379 --name PAYPAL-CLIENT-ID --value "YOUR_PAYPAL_CLIENT_ID"
az keyvault secret set --vault-name ecomm-kv-4379 --name PAYPAL-CLIENT-SECRET --value "YOUR_PAYPAL_CLIENT_SECRET"
```

### Azure Communication Services (Optional - for email notifications)
- `AZURE_COMMUNICATION_CONNECTION_STRING` = Your Azure Communication Services connection string

### Azure AD B2C (Optional - for advanced authentication)
- `AZURE_AD_B2C_CLIENT_ID` = Your Azure AD B2C client ID
- `AZURE_AD_B2C_AUTHORITY` = Your Azure AD B2C authority URL
- `AZURE_AD_B2C_CLIENT_SECRET` = Your Azure AD B2C client secret
- `AZURE_AD_B2C_DOMAIN` = Your Azure AD B2C domain

### Azure Notification Hub (Optional - for push notifications)
- `AZURE_NOTIFICATION_HUB_CONNECTION_STRING` = Your notification hub connection string
- `AZURE_NOTIFICATION_HUB_NAME` = Your notification hub name

### App Insights (Optional - for monitoring)
- `APPINSIGHTS_INSTRUMENTATIONKEY` = Your Application Insights key

## 🔧 How to Add Settings

### Via Azure Portal
1. Go to https://portal.azure.com
2. Navigate to App Service → ecomm-app-4379
3. Click **Configuration** → **Application settings**
4. Click **+ New application setting**
5. Add name and value
6. Click **Save** and **Restart** the app

### Via Azure CLI
```powershell
az webapp config appsettings set --name ecomm-app-4379 --resource-group ecommerce-full-rg --settings "SETTING_NAME=value"
```

### For Key Vault References
Use this format for sensitive values:
```
@Microsoft.KeyVault(SecretUri=https://ecomm-kv-4379.vault.azure.net/secrets/SECRET-NAME/)
```

## 📝 Notes
- All secrets are securely stored in Azure Key Vault
- App Service uses Managed Identity to access Key Vault (no passwords needed)
- Update `CLIENT_URL` to your actual frontend URL once deployed
- Remove Cloudinary settings once fully migrated to Azure Blob Storage
