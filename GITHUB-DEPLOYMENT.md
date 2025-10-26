# 🚀 GitHub Actions Deployment Guide

## ✅ Pre-Deployment Checklist

Your code is ready! Here's what we have:

- ✅ Server tested and working locally
- ✅ Azure Blob Storage configured
- ✅ MongoDB connected
- ✅ Environment variables set in Azure
- ✅ GitHub Actions workflow created
- ✅ Publish profile generated

---

## 📋 Step-by-Step Deployment

### Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `ecommerce-azure` (or any name you prefer)
3. **Important**: Make it **Public** (or have GitHub Pro for private repos with Actions)
4. **Do NOT** initialize with README, .gitignore, or license
5. Click "Create repository"

### Step 2: Add GitHub Secret

1. Go to your new repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `AZURE_WEBAPP_PUBLISH_PROFILE`
5. Value: Open `publish-profile-github.xml` file and copy **ALL** content
6. Click **Add secret**

### Step 3: Push Your Code

Run these commands in PowerShell:

```powershell
cd D:\Users\Radhika\Documents\E-commerce

# Check current branch
git branch

# If not on external branch, switch to it
git checkout external

# Add all files
git add .

# Commit
git commit -m "Ready for Azure deployment with GitHub Actions"

# Add your GitHub repository as remote (replace YOUR_USERNAME and YOUR_REPO)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push to GitHub
git push -u origin external
```

**Replace YOUR_USERNAME and YOUR_REPO** with your actual GitHub username and repository name!

### Step 4: Monitor Deployment

1. Go to your GitHub repository
2. Click **Actions** tab
3. You'll see the "Deploy Backend to Azure App Service" workflow running
4. Click on it to watch the deployment progress

### Step 5: Verify Deployment

Once the workflow completes successfully, test your API:

```powershell
# Test health endpoint
curl https://ecomm-app-4379.azurewebsites.net/api/health
```

You should see:
```json
{
  "status": "healthy",
  "timestamp": "...",
  "environment": "production",
  "database": "connected",
  "azureStorage": "configured"
}
```

---

## 🔄 Future Deployments

Every time you push changes to the `external` branch (or `main`/`master`), GitHub Actions will automatically:

1. Install dependencies
2. Create deployment package
3. Deploy to Azure
4. Run health checks
5. Notify you of success/failure

---

## 🎯 Quick Commands Reference

### To deploy changes:
```powershell
cd D:\Users\Radhika\Documents\E-commerce
git add .
git commit -m "Your commit message"
git push origin external
```

### To manually trigger deployment:
1. Go to GitHub → Actions
2. Select "Deploy Backend to Azure App Service"
3. Click "Run workflow"
4. Select branch and click "Run workflow"

---

## 🌐 Your Application URLs

- **Backend API**: https://ecomm-app-4379.azurewebsites.net
- **Health Check**: https://ecomm-app-4379.azurewebsites.net/api/health
- **API Base URL**: https://ecomm-app-4379.azurewebsites.net/api

### Update Frontend Configuration

In your client app, update the API URL to:
```javascript
const API_URL = "https://ecomm-app-4379.azurewebsites.net/api";
```

---

## 📝 Environment Variables (Already Set in Azure)

These are configured in Azure App Service → Configuration:

```
NODE_ENV=production
PORT=8080
MONGO_DBURL=mongodb+srv://...
SECRET_KEY=onlinemayuresh29
AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=https;...
CLOUDINARY_CLOUD_NAME=ds20dwlrs
CLOUDINARY_API_KEY=458753332856375
CLOUDINARY_API_SECRET=tcqI98ArkHPoSZt2lPsuDQQ5cfs
```

**Note**: Never commit `.env` file to GitHub! It's already in `.gitignore`.

---

## 🔧 Workflow Features

Your GitHub Actions workflow includes:

✅ **Automatic dependency installation**
✅ **Production build optimization**
✅ **Secure secret management**
✅ **Deployment health checks**
✅ **Error notifications**
✅ **Manual deployment trigger**

---

## 🐛 Troubleshooting

### Deployment fails in GitHub Actions

**Check:**
1. GitHub secret `AZURE_WEBAPP_PUBLISH_PROFILE` is set correctly
2. Workflow file is in `.github/workflows/` directory
3. Check workflow logs in GitHub Actions tab

### App is deployed but not responding

**Check:**
```powershell
# View Azure logs
az webapp log tail --name ecomm-app-4379 --resource-group ecommerce-full-rg

# Restart app
az webapp restart --name ecomm-app-4379 --resource-group ecommerce-full-rg
```

### Health check fails

**Possible causes:**
- Database connection issue (check MongoDB Atlas IP whitelist)
- Azure Storage issue (verify connection string in Azure Portal)
- Missing environment variables

**Solution:**
1. Go to Azure Portal → App Service → Configuration
2. Verify all environment variables are set
3. Restart the app service

---

## 📊 Monitoring Your Deployment

### View Deployment Logs
- GitHub Actions logs: GitHub → Actions → Select workflow run
- Azure App Service logs: Azure Portal → App Service → Log stream

### Check Application Status
```powershell
# App status
az webapp show --name ecomm-app-4379 --resource-group ecommerce-full-rg --query state

# Recent logs
az webapp log download --name ecomm-app-4379 --resource-group ecommerce-full-rg
```

---

## ✨ What Happens on Each Push?

1. **GitHub Actions triggers** when you push to external/main/master branch
2. **Checks out your code** from the repository
3. **Installs Node.js 20** and dependencies
4. **Creates deployment package** (excludes unnecessary files)
5. **Deploys to Azure** using the publish profile
6. **Waits 30 seconds** for app to start
7. **Runs health checks** (up to 10 attempts)
8. **Reports success or failure** in GitHub Actions

---

## 🎉 Success Criteria

Your deployment is successful when:

✅ GitHub Actions workflow completes without errors
✅ Health check returns 200 OK
✅ `https://ecomm-app-4379.azurewebsites.net/api/health` shows healthy status
✅ Database shows "connected"
✅ Azure Storage shows "configured"

---

## 📞 Need Help?

1. Check GitHub Actions logs first
2. Check Azure App Service logs
3. Verify environment variables in Azure Portal
4. Test locally to ensure code works before pushing

---

**Your backend is ready to deploy! Follow the steps above and you'll be live in minutes! 🚀**
