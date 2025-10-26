# 🔧 Azure Environment Variables - REQUIRED SETUP

## ❌ Current Problem
Your app is failing because these critical environment variables are **MISSING** in Azure App Service.

## ✅ Variables You Need to Add in Azure Portal

Go to: **Azure Portal → Your App Service (ecomm-app-4379) → Configuration → Application Settings**

Add these environment variables:

### **1. Authentication & Security**
```
SECRET_KEY = onlinemayuresh29
```
(Used for JWT token signing - without this, login/auth will fail)

### **2. Azure Storage (for product images)**
```
AZURE_STORAGE_CONNECTION_STRING = <YOUR_STORAGE_ACCOUNT_CONNECTION_STRING>
```
**To get this:**
- Go to Azure Portal → Storage Accounts → ecomm-storage-4379 (or your storage name)
- Click "Access keys" → Copy "Connection string"

### **3. Cloudinary (image upload fallback)**
```
CLOUDINARY_CLOUD_NAME = ds20dwlrs
CLOUDINARY_API_KEY = 458753332856375
CLOUDINARY_API_SECRET = tcqI98ArkHPoSZt2lPsuDQQ5cfs
```

### **4. PayPal (if using PayPal payments)**
```
PAYPAL_CLIENT_ID = <your_paypal_client_id>
PAYPAL_CLIENT_SECRET = <your_paypal_secret>
PAYPAL_MODE = sandbox
```
(Skip this if you're not using PayPal yet)

### **5. Azure Key Vault Secrets (Optional - for Key Vault integration)**
If using Key Vault, add these secrets with these **exact names**:
- `MONGO-URI` (note: uses hyphens, not underscores)
- `JWT-SECRET-KEY`
- `CLOUDINARY-CLOUD-NAME`
- `CLOUDINARY-API-KEY`
- `CLOUDINARY-API-SECRET`
- `PAYPAL-CLIENT-ID`
- `PAYPAL-CLIENT-SECRET`
- `PAYPAL-MODE`

---

## 📋 Already Configured (from appsettings.json)
✅ MONGO_DBURL  
✅ CLIENT_URL  
✅ PORT  
✅ NODE_ENV  
✅ KEY_VAULT_NAME  

---

## 🚀 After Adding Variables

1. **Save** the configuration in Azure Portal
2. **Restart** your App Service
3. Check logs: Azure Portal → Your App Service → Log stream

---

## 🔍 How to Verify

After restart, your app should show in logs:
```
Database connected
Azure Blob Storage initialized successfully
Server is Running on port: 8080
```

If you see "Azure Storage connection string not set" - that's okay if using Cloudinary only.
