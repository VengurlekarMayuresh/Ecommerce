# Azure IAM & Notification Services Setup

This guide covers setting up **Azure AD B2C** for Identity and Access Management (IAM) and **Azure Communication Services** + **Notification Hubs** for order notifications.

---

## 🔐 Azure AD B2C Setup (IAM with Role-Based Access)

### Overview
Azure AD B2C provides enterprise-grade authentication with custom roles:
- **Admin Role**: Manage products, orders, users, analytics
- **Customer Role**: Browse products, place orders, view own orders

### 1. Create Azure AD B2C Tenant

```bash
# Set variables
RESOURCE_GROUP="ecommerce-rg"
LOCATION="eastus"
B2C_TENANT_NAME="ecommerceb2c"  # Must be unique
B2C_DOMAIN="${B2C_TENANT_NAME}.onmicrosoft.com"

# Create Azure AD B2C tenant (via Portal - CLI limited)
```

**Via Azure Portal:**
1. Go to [Azure Portal](https://portal.azure.com)
2. Create a resource → **Azure Active Directory B2C**
3. Select **Create a new Azure AD B2C Tenant**
4. Organization name: `EcommerceB2C`
5. Initial domain: `ecommerceb2c` (must be unique)
6. Country: United States
7. Click **Create**

### 2. Register Application in Azure AD B2C

1. Go to your B2C tenant
2. **App registrations** → **New registration**
3. Settings:
   - Name: `Ecommerce-API`
   - Supported account types: **Accounts in any identity provider or organizational directory**
   - Redirect URI: 
     - Web: `https://ecommerce-api.azurewebsites.net/auth/callback`
     - SPA: `https://<your-frontend>.azurestaticapps.net`
4. Click **Register**

### 3. Configure Application

#### API Permissions:
1. **API permissions** → **Add a permission**
2. **Microsoft Graph** → **Delegated permissions**
3. Select: `email`, `openid`, `profile`, `User.Read`
4. Click **Grant admin consent**

#### Certificates & Secrets:
1. **Certificates & secrets** → **New client secret**
2. Description: `API Secret`
3. Expires: 24 months
4. Click **Add**
5. **Copy the secret value** (you won't see it again!)

#### Expose an API:
1. **Expose an API** → **Add a scope**
2. Application ID URI: `api://{clientId}`
3. Scope name: `access_as_user`
4. Admin consent display name: `Access API as user`
5. Click **Add scope**

### 4. Create User Flows

#### Sign-up and Sign-in Flow:
1. **User flows** → **New user flow**
2. Select **Sign up and sign in** → **Recommended**
3. Name: `B2C_1_signupsignin`
4. Identity providers: **Email signup**
5. User attributes and claims:
   - Collect: Email Address, Display Name, Given Name, Surname
   - Return: Email Addresses, Display Name, User's Object ID
6. Click **Create**

#### Profile Editing Flow:
1. Create another user flow
2. Select **Profile editing**
3. Name: `B2C_1_profileediting`
4. Configure similar attributes

### 5. Custom Attributes for Roles

1. **User attributes** → **Add**
2. Name: `Role`
3. Data type: `String`
4. Description: `User role (admin/customer)`
5. Click **Create**

### 6. Configure App Settings

Add to Azure Key Vault:

```bash
KEY_VAULT_NAME="ecommerce-keyvault"

# Get these values from your B2C tenant
AZURE_AD_B2C_CLIENT_ID="<your-client-id>"
AZURE_AD_B2C_CLIENT_SECRET="<your-client-secret>"
AZURE_AD_B2C_TENANT="ecommerceb2c"
AZURE_AD_B2C_DOMAIN="ecommerceb2c.onmicrosoft.com"
AZURE_AD_B2C_AUTHORITY="https://${AZURE_AD_B2C_TENANT}.b2clogin.com/${AZURE_AD_B2C_DOMAIN}/B2C_1_signupsignin"

# Add to Key Vault
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "AZURE-AD-B2C-CLIENT-ID" --value "$AZURE_AD_B2C_CLIENT_ID"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "AZURE-AD-B2C-CLIENT-SECRET" --value "$AZURE_AD_B2C_CLIENT_SECRET"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "AZURE-AD-B2C-AUTHORITY" --value "$AZURE_AD_B2C_AUTHORITY"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "AZURE-AD-B2C-DOMAIN" --value "$AZURE_AD_B2C_DOMAIN"
```

### 7. Update Backend Dependencies

```bash
cd server
npm install @azure/msal-node --save
```

---

## 📧 Azure Communication Services (Email Notifications)

### 1. Create Communication Services Resource

```bash
COMMUNICATION_SERVICE_NAME="ecommerce-communication"

# Create Communication Services
az communication create \
  --name $COMMUNICATION_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --location "global" \
  --data-location "United States"

# Get connection string
CONNECTION_STRING=$(az communication list-key \
  --name $COMMUNICATION_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query primaryConnectionString -o tsv)

# Add to Key Vault
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "AZURE-COMMUNICATION-CONNECTION-STRING" --value "$CONNECTION_STRING"
```

### 2. Configure Email Service

#### Option A: Use Azure Managed Domain
1. Go to **Communication Services** → **Email** → **Provision domains**
2. Select **Azure Managed Domain**
3. Domain: `AzureManagedDomain`
4. Click **Add**
5. Sender address: `DoNotReply@{your-domain}.azurecomm.net`

#### Option B: Use Custom Domain
1. **Provision domains** → **Add your own domain**
2. Enter your domain: `ecommerce.com`
3. Add DNS records (TXT, CNAME) to your domain provider
4. Wait for verification
5. Configure sender address: `orders@ecommerce.com`

### 3. Connect Email to Communication Service

```bash
# Get email service resource ID
EMAIL_RESOURCE_ID=$(az communication email list \
  --resource-group $RESOURCE_GROUP \
  --query "[0].id" -o tsv)

# Link email to communication service
az communication update \
  --name $COMMUNICATION_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --linked-domains $EMAIL_RESOURCE_ID
```

### 4. Configure Sender Address

```bash
# Add sender address to Key Vault
SENDER_EMAIL="DoNotReply@{your-azurecomm-domain}.azurecomm.net"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "AZURE-COMMUNICATION-SENDER-ADDRESS" --value "$SENDER_EMAIL"

# Admin notification email
ADMIN_EMAIL="admin@yourdomain.com"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "ADMIN-NOTIFICATION-EMAIL" --value "$ADMIN_EMAIL"
```

### 5. Update Backend Dependencies

```bash
cd server
npm install @azure/communication-email --save
```

---

## 🔔 Azure Notification Hubs (Push Notifications)

### 1. Create Notification Hub Namespace

```bash
NOTIFICATION_NAMESPACE="ecommerce-notifications"
NOTIFICATION_HUB="ecommerce-hub"

# Create namespace
az notification-hub namespace create \
  --name $NOTIFICATION_NAMESPACE \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard

# Create notification hub
az notification-hub create \
  --name $NOTIFICATION_HUB \
  --namespace-name $NOTIFICATION_NAMESPACE \
  --resource-group $RESOURCE_GROUP
```

### 2. Configure Firebase Cloud Messaging (FCM)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing
3. **Project Settings** → **Cloud Messaging**
4. Copy **Server Key** and **Sender ID**

#### Add FCM to Notification Hub:
```bash
FCM_SERVER_KEY="<your-fcm-server-key>"

# Update notification hub with FCM credentials
az notification-hub credential gcm update \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $NOTIFICATION_NAMESPACE \
  --notification-hub-name $NOTIFICATION_HUB \
  --google-api-key $FCM_SERVER_KEY
```

### 3. Get Connection String

```bash
# Get connection string
NOTIFICATION_CONNECTION=$(az notification-hub authorization-rule list-keys \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $NOTIFICATION_NAMESPACE \
  --notification-hub-name $NOTIFICATION_HUB \
  --name DefaultFullSharedAccessSignature \
  --query primaryConnectionString -o tsv)

# Add to Key Vault
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "AZURE-NOTIFICATION-HUB-CONNECTION-STRING" --value "$NOTIFICATION_CONNECTION"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "AZURE-NOTIFICATION-HUB-NAME" --value "$NOTIFICATION_HUB"
```

### 4. Update Backend Dependencies

```bash
cd server
npm install azure-sb --save
```

---

## 🔗 Integration with Backend

### Update server.js

```javascript
// Add at the top of server.js
const { initializeAzureADB2C } = require('./config/azure-ad-b2c');
const { initializeCommunicationServices } = require('./config/azure-communication');
const { initializeNotificationHub } = require('./config/azure-notification-hub');

// Initialize services after Key Vault
async function initializeServices() {
  // Load secrets from Key Vault
  const secrets = await loadSecrets();
  
  // Set environment variables from secrets
  process.env.AZURE_AD_B2C_CLIENT_ID = secrets['AZURE-AD-B2C-CLIENT-ID'];
  process.env.AZURE_AD_B2C_CLIENT_SECRET = secrets['AZURE-AD-B2C-CLIENT-SECRET'];
  process.env.AZURE_AD_B2C_AUTHORITY = secrets['AZURE-AD-B2C-AUTHORITY'];
  process.env.AZURE_AD_B2C_DOMAIN = secrets['AZURE-AD-B2C-DOMAIN'];
  
  process.env.AZURE_COMMUNICATION_CONNECTION_STRING = secrets['AZURE-COMMUNICATION-CONNECTION-STRING'];
  process.env.AZURE_COMMUNICATION_SENDER_ADDRESS = secrets['AZURE-COMMUNICATION-SENDER-ADDRESS'];
  process.env.ADMIN_NOTIFICATION_EMAIL = secrets['ADMIN-NOTIFICATION-EMAIL'];
  
  process.env.AZURE_NOTIFICATION_HUB_CONNECTION_STRING = secrets['AZURE-NOTIFICATION-HUB-CONNECTION-STRING'];
  process.env.AZURE_NOTIFICATION_HUB_NAME = secrets['AZURE-NOTIFICATION-HUB-NAME'];
  
  // Initialize Azure services
  initializeAzureADB2C();
  initializeCommunicationServices();
  initializeNotificationHub();
}

initializeServices().then(() => {
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
});
```

### Update Routes

Replace your existing auth/order routes with the IAM-protected versions:

```javascript
// Import IAM middleware
const { requireAdmin, requireCustomer } = require('./config/azure-ad-b2c');

// Example: Admin-only route
app.use('/api/admin/products', requireAdmin, adminProductRouter);

// Example: Customer route
app.use('/api/shop/orders', requireCustomer, shopOrderRouter);

// Example: Mixed access
app.use('/api/orders', orderRoutesWithIAM);
```

---

## 🧪 Testing

### Test Email Notifications

```bash
# Test endpoint (add to your routes)
# POST /api/test/email
curl -X POST https://ecommerce-api.azurewebsites.net/api/test/email \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "orderId": "TEST123"
  }'
```

### Test Push Notifications

```bash
# Register device first
# POST /api/notifications/register
curl -X POST https://ecommerce-api.azurewebsites.net/api/notifications/register \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "deviceToken": "your-fcm-device-token"
  }'

# Send test push
# POST /api/test/push
curl -X POST https://ecommerce-api.azurewebsites.net/api/test/push \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "orderId": "TEST123"
  }'
```

### Test IAM

```bash
# Get token from Azure AD B2C (via frontend)
TOKEN="<your-azure-ad-b2c-token>"

# Test admin endpoint
curl -X GET https://ecommerce-api.azurewebsites.net/api/admin/products \
  -H "Authorization: Bearer $TOKEN"

# Test customer endpoint
curl -X GET https://ecommerce-api.azurewebsites.net/api/shop/orders \
  -H "Authorization: Bearer $TOKEN"
```

---

## 📊 Notification Flow

### Order Lifecycle:

1. **Order Placed** → Customer receives email + push → Admin receives email
2. **Order Shipped** → Customer receives email + push (with tracking)
3. **Order Delivered** → Customer receives email + push
4. **Order Cancelled** → Customer receives email + push (with reason)

### Auto-Trigger:
Notifications are automatically sent when order status changes via the `autoNotifyOrderUpdate` middleware.

---

## 🔒 Security & Roles

### Role Assignment:

**Admin Users:**
- Manually set `extension_Role = "admin"` in Azure AD B2C user properties
- Or create custom policy to assign roles during registration

**Customer Users:**
- Default role is `customer`
- Assigned automatically during sign-up

### Permissions Matrix:

| Action | Admin | Customer |
|--------|-------|----------|
| View Products | ✅ | ✅ |
| Create Product | ✅ | ❌ |
| Place Order | ✅ | ✅ |
| View All Orders | ✅ | ❌ |
| View Own Orders | ✅ | ✅ |
| Update Order Status | ✅ | ❌ |
| Cancel Order | ✅ | ✅ (own only) |

---

## 💰 Cost Estimation

### Azure AD B2C:
- First 50,000 monthly authentications: **FREE**
- Additional: $0.00325 per authentication

### Communication Services (Email):
- First 100 emails/month: **FREE**
- Additional: $0.000025 per email (~$2.50 per 100,000)

### Notification Hubs:
- Standard tier: **$10/month**
- Includes: 10M pushes/month

**Estimated Monthly Cost:** ~$10-15 for small to medium traffic

---

## 📚 Additional Resources

- [Azure AD B2C Documentation](https://docs.microsoft.com/azure/active-directory-b2c/)
- [Communication Services Email](https://docs.microsoft.com/azure/communication-services/concepts/email/email-overview)
- [Notification Hubs](https://docs.microsoft.com/azure/notification-hubs/)

---

## 🎯 Next Steps

1. ✅ Configure Azure AD B2C tenant
2. ✅ Set up Communication Services for email
3. ✅ Configure Notification Hubs for push
4. ✅ Update backend with IAM middleware
5. ✅ Test notification flow
6. 📱 Integrate frontend with Azure AD B2C login
7. 📱 Add FCM to mobile app (if applicable)

Your e-commerce platform now has **enterprise-grade IAM** and **multi-channel notifications**! 🎉
