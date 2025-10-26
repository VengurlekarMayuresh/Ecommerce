# 🛒 E-commerce Full Stack Application - Azure Deployment

A modern, full-stack e-commerce application built with **React**, **Node.js**, **Express**, and **MongoDB**, fully integrated with **Azure Cloud Services**.

## 🏗️ Architecture

### Frontend
- **Framework**: React 19 + Vite
- **UI Library**: Radix UI + Tailwind CSS
- **State Management**: Redux Toolkit
- **Hosting**: Azure Static Web Apps

### Backend
- **Runtime**: Node.js 20
- **Framework**: Express.js
- **Database**: MongoDB (Atlas or Azure Cosmos DB)
- **Hosting**: Azure App Service

### Azure Services Integration
- ☁️ **Azure App Service** - Backend API hosting
- 🌐 **Azure Static Web Apps** - Frontend hosting
- 💾 **Azure Blob Storage** - Product image storage
- 📊 **Azure Application Insights** - Monitoring & analytics
- 🔐 **Azure Key Vault** - Secrets management (optional)
- 🗄️ **Azure Cosmos DB** - MongoDB API (optional)

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ 
- Azure Account ([Get free account](https://azure.microsoft.com/free/))
- Azure CLI ([Install](https://docs.microsoft.com/cli/azure/install-azure-cli))
- GitHub Account

### Local Development

```bash
# Clone repository
git clone <your-repo-url>
cd E-commerce

# Install backend dependencies
cd server
npm install

# Install frontend dependencies
cd ../client
npm install

# Run backend (port 5000)
cd ../server
npm run dev

# Run frontend (port 5173)
cd ../client
npm run dev
```

### Environment Setup

**Backend** (`server/.env`):
```env
MONGO_DBURL=your_mongodb_connection_string
SECRET_KEY=your_jwt_secret
AZURE_STORAGE_CONNECTION_STRING=your_azure_storage_connection
APPLICATIONINSIGHTS_CONNECTION_STRING=your_app_insights_connection
CLIENT_URL=http://localhost:5173
CLOUDINARY_CLOUD_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_key
CLOUDINARY_API_SECRET=your_cloudinary_secret
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_secret
```

**Frontend** (`client/.env`):
```env
VITE_API_URL=http://localhost:5000/api
```

## 🌐 Azure Deployment

### Option 1: Quick Deploy (Automated)

```powershell
# Run PowerShell script
.\azure-quick-deploy.ps1 `
  -ResourceGroup "ecommerce-rg" `
  -Location "eastus" `
  -AppName "ecomm-api" `
  -StaticAppName "ecommerce-frontend"
```

### Option 2: Manual Deployment

See **[AZURE-DEPLOYMENT.md](./AZURE-DEPLOYMENT.md)** for detailed step-by-step instructions.

### GitHub Actions CI/CD

This project includes automated deployment workflows:

1. **`.github/workflows/azure-static-web-apps-deploy.yml`** - Deploys frontend
2. **`.github/workflows/azure-app-service-deploy.yml`** - Deploys backend

**Setup GitHub Secrets**:
- `AZURE_WEBAPP_PUBLISH_PROFILE` - Backend publish profile
- `AZURE_STATIC_WEB_APPS_API_TOKEN` - Frontend deployment token

Push to `main` branch to trigger automatic deployment! 🚀

## 📁 Project Structure

```
E-commerce/
├── client/                      # Frontend React app
│   ├── src/
│   │   ├── components/         # Reusable UI components
│   │   ├── pages/             # Page components
│   │   ├── store/             # Redux store
│   │   └── config/            # Configuration
│   ├── staticwebapp.config.json
│   └── package.json
│
├── server/                      # Backend API
│   ├── config/                 # Azure integrations
│   │   ├── azure-storage.js
│   │   ├── azure-keyvault.js
│   │   └── app-insights.js
│   ├── controllers/            # Route controllers
│   ├── models/                 # MongoDB models
│   ├── routes/                 # API routes
│   ├── middleware/             # Custom middleware
│   ├── server.js              # Main entry point
│   ├── server-azure.js        # Azure-optimized entry
│   ├── web.config             # IIS configuration
│   └── package.json
│
├── .github/
│   └── workflows/             # CI/CD pipelines
│
├── AZURE-DEPLOYMENT.md        # Detailed deployment guide
├── README.md                  # This file
└── azure-quick-deploy.ps1     # Automated deployment script
```

## 🔧 Features

### Customer Features
- 🛍️ Browse products with filters (category, brand, price)
- 🔍 Search functionality
- 🛒 Shopping cart management
- ⭐ Product reviews and ratings
- 📦 Order tracking
- 👤 User authentication & profile
- 💳 PayPal payment integration

### Admin Features
- 📊 Dashboard with analytics
- ➕ Add/Edit/Delete products
- 🖼️ Image upload to Azure Blob Storage
- 📋 Order management
- 👥 User management

## 🛠️ Tech Stack

### Frontend
- React 19.1
- Redux Toolkit
- React Router v7
- Tailwind CSS 4
- Radix UI Components
- Axios
- Vite

### Backend
- Node.js 20
- Express.js 5
- MongoDB/Mongoose
- JWT Authentication
- Azure SDK
- Application Insights
- Multer (file upload)
- PayPal SDK

## 📊 Monitoring

### Application Insights Dashboard
Monitor your app in real-time:
- Request rates and response times
- Failed requests and exceptions
- Server performance metrics
- Custom events and traces

Access via: Azure Portal → Application Insights → ecommerce-insights

### Health Check Endpoints
- **Backend**: `https://your-app.azurewebsites.net/api/health`
- **Frontend**: `https://your-static-app.azurestaticapps.net`

## 🔐 Security

- JWT-based authentication
- HTTP-only cookies
- CORS protection
- Environment-based secrets
- Azure Key Vault integration (optional)
- Azure AD B2C ready (optional)

## 🧪 Testing

```bash
# Run backend tests
cd server
npm test

# Run frontend tests
cd client
npm test
```

## 📝 API Documentation

### Authentication Endpoints
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user

### Product Endpoints
- `GET /api/shop/products` - Get all products
- `GET /api/shop/products/:id` - Get product by ID
- `GET /api/shop/search` - Search products

### Order Endpoints
- `POST /api/shop/order/create` - Create order
- `GET /api/shop/order/list` - Get user orders
- `GET /api/shop/order/:id` - Get order details

### Admin Endpoints
- `POST /api/admin/products` - Add product
- `PUT /api/admin/products/:id` - Update product
- `DELETE /api/admin/products/:id` - Delete product
- `GET /api/admin/orders` - Get all orders

## 🐛 Troubleshooting

### Common Issues

**Issue**: Deployment fails
```bash
# Check App Service logs
az webapp log tail --name ecomm-api --resource-group ecommerce-rg
```

**Issue**: CORS errors
- Update `CLIENT_URL` environment variable in Azure App Service

**Issue**: Images not loading
- Verify Azure Blob Storage connection string
- Check container public access settings

**Issue**: Database connection fails
- Verify MongoDB connection string
- Check IP whitelist in MongoDB Atlas

## 💰 Cost Estimate

**Development Environment**:
- App Service (B1): ~$13/month
- Static Web Apps (Free tier): $0
- Storage (5GB): ~$0.10/month
- App Insights (5GB): Free tier
- **Total**: ~$13-15/month

**Production Environment**:
- App Service (P1V2): ~$73/month
- Static Web Apps (Standard): $9/month  
- Storage (50GB): ~$1/month
- App Insights: ~$5/month
- **Total**: ~$88-90/month

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is licensed under the ISC License.

## 📞 Support

- 📧 Email: your-email@example.com
- 📚 Documentation: [AZURE-DEPLOYMENT.md](./AZURE-DEPLOYMENT.md)
- 🐛 Issues: [GitHub Issues](https://github.com/your-username/your-repo/issues)

## 🙏 Acknowledgments

- Azure documentation team
- React and Node.js communities
- All open-source contributors

---

**Built with ❤️ and deployed on Azure ☁️**
