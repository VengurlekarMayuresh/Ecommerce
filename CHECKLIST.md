# ✅ Azure Deployment Checklist

## Pre-Deployment Checklist

### 1. Install Required Dependencies
```powershell
cd server
npm install applicationinsights @azure/service-bus @azure/cosmos winston winston-azure-application-insights
cd ../client
npm install
```
- [ ] Server dependencies installed
- [ ] Client dependencies installed
- [ ] No installation errors

### 2. Azure CLI Setup
```powershell
az --version
az login
```
- [ ] Azure CLI installed
- [ ] Successfully logged into Azure
- [ ] Correct subscription selected

### 3. Create Azure Resources

Run the quick deploy script:
```powershell
.\azure-quick-deploy.ps1 -ResourceGroup "ecommerce-rg" -Location "eastus" -AppName "your-unique-name" -StaticAppName "your-frontend-name"
```

**OR manually create:**
- [ ] Resource Group created
- [ ] Storage Account created
- [ ] Blob container "product-images" created
- [ ] Application Insights created
- [ ] App Service Plan created
- [ ] Web App (App Service) created
- [ ] Static Web App created (optional, can be done via GitHub)

### 4. Configure Environment Variables

In Azure Portal → App Service → Configuration → Application Settings:

- [ ] `NODE_ENV=production`
- [ ] `PORT=8080`
- [ ] `MONGO_DBURL` (your MongoDB connection string)
- [ ] `SECRET_KEY` (your JWT secret)
- [ ] `AZURE_STORAGE_CONNECTION_STRING`
- [ ] `APPLICATIONINSIGHTS_CONNECTION_STRING`
- [ ] `CLIENT_URL` (your Static Web App URL)
- [ ] `CLOUDINARY_CLOUD_NAME`
- [ ] `CLOUDINARY_API_KEY`
- [ ] `CLOUDINARY_API_SECRET`
- [ ] `PAYPAL_CLIENT_ID`
- [ ] `PAYPAL_CLIENT_SECRET`
- [ ] `PAYPAL_MODE=sandbox`

### 5. GitHub Setup

- [ ] GitHub repository created
- [ ] Repository is public or you have GitHub Pro
- [ ] Local repo connected to GitHub remote

```powershell
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main
```

### 6. GitHub Secrets

In GitHub → Settings → Secrets and variables → Actions:

- [ ] `AZURE_WEBAPP_PUBLISH_PROFILE` added
- [ ] `AZURE_STATIC_WEB_APPS_API_TOKEN` added (if using Static Web App workflow)

**Get publish profile:**
```powershell
az webapp deployment list-publishing-profiles --name YOUR_APP --resource-group ecommerce-rg --xml
```

### 7. Update Workflow Configuration

Edit `.github/workflows/azure-app-service-deploy.yml`:
- [ ] Update `AZURE_WEBAPP_NAME` to your actual app name (line 13)

Edit `.github/workflows/azure-static-web-apps-deploy.yml`:
- [ ] Verify `app_location` is "/client" (line 51)
- [ ] Verify `output_location` is "dist" (line 53)

---

## Deployment Checklist

### 8. Initial Deployment

```powershell
# Push to GitHub to trigger deployment
git push origin main
```

- [ ] Code pushed to GitHub
- [ ] GitHub Actions workflows triggered
- [ ] Backend workflow completed successfully
- [ ] Frontend workflow completed successfully

### 9. Verify Deployment

```powershell
# Check backend health
curl https://YOUR_APP.azurewebsites.net/api/health

# Check frontend
curl https://YOUR_STATIC_APP.azurestaticapps.net
```

- [ ] Backend health check returns 200 OK
- [ ] Frontend loads without errors
- [ ] Can access frontend URL in browser
- [ ] API calls from frontend work correctly

### 10. Database Configuration

For MongoDB Atlas:
- [ ] Azure App Service IP addresses whitelisted
- [ ] OR "Allow access from Azure services" enabled
- [ ] Database connection working from Azure

### 11. Storage Configuration

- [ ] Blob container has public read access for blobs
- [ ] Can upload images from admin panel
- [ ] Images are accessible via public URLs

### 12. Application Insights

In Azure Portal → Application Insights:
- [ ] Receiving telemetry data
- [ ] No critical errors in logs
- [ ] Request metrics showing up

---

## Post-Deployment Checklist

### 13. Testing

- [ ] Can register new user account
- [ ] Can login successfully
- [ ] Can browse products
- [ ] Can add items to cart
- [ ] Can search products
- [ ] Admin can login
- [ ] Admin can add products
- [ ] Admin can upload images (to Azure Blob Storage)
- [ ] Can create test order
- [ ] PayPal integration works (sandbox mode)

### 14. Performance

- [ ] Frontend loads in < 3 seconds
- [ ] API responses < 500ms
- [ ] Images load correctly
- [ ] No console errors in browser
- [ ] Mobile responsive design works

### 15. Security

- [ ] HTTPS enabled (automatic with Azure)
- [ ] CORS configured correctly
- [ ] JWT authentication working
- [ ] Sensitive data in environment variables (not hardcoded)
- [ ] `.env` files not committed to GitHub

### 16. Monitoring Setup

- [ ] Application Insights collecting data
- [ ] Alerts configured (optional)
- [ ] Log streaming enabled in App Service

### 17. Cleanup & Optimization

- [ ] Removed old deployment files
- [ ] No sensitive data in repository
- [ ] `.gitignore` properly configured
- [ ] README updated with correct URLs
- [ ] Documentation complete

---

## Troubleshooting Reference

### If Backend Deployment Fails:
```powershell
# Check logs
az webapp log tail --name YOUR_APP --resource-group ecommerce-rg

# Restart app service
az webapp restart --name YOUR_APP --resource-group ecommerce-rg
```

### If Frontend Build Fails:
- Check `output_location` in workflow matches Vite build output (`dist`)
- Verify all dependencies in `client/package.json`
- Check GitHub Actions logs for specific errors

### If Database Connection Fails:
- Verify MongoDB connection string
- Check Azure App Service outbound IP addresses
- Whitelist IPs in MongoDB Atlas

### If Images Don't Upload:
- Check `AZURE_STORAGE_CONNECTION_STRING` is set
- Verify blob container exists
- Check container has public blob access

---

## Final Verification

Once everything is checked:

- [ ] Application fully functional on Azure
- [ ] All Azure services integrated and working
- [ ] Documentation complete
- [ ] GitHub repository clean and organized
- [ ] Monitoring and logging configured
- [ ] Cost monitoring set up in Azure Portal

---

## 🎉 Success Criteria

Your deployment is successful when:

✅ Frontend accessible at your Azure Static Web App URL  
✅ Backend API responding at your Azure App Service URL  
✅ Health check endpoint returns healthy status  
✅ Database connections working  
✅ Images uploading to Azure Blob Storage  
✅ Application Insights showing telemetry  
✅ No errors in Azure logs  
✅ All core features working end-to-end  

---

## Next Steps After Successful Deployment

1. **Custom Domain** (Optional)
   - Configure custom domain for frontend
   - Configure custom domain for backend API
   - Set up SSL certificates

2. **CDN Setup** (Optional)
   - Enable Azure CDN for static assets
   - Configure caching rules

3. **Scale Up** (When needed)
   - Upgrade App Service plan
   - Enable autoscaling
   - Configure load balancing

4. **Backup Strategy**
   - Set up database backups
   - Configure App Service backup

5. **Production Optimization**
   - Enable Application Insights alerts
   - Set up Azure Monitor dashboards
   - Configure autoscaling rules

---

**Last Updated**: Ready for deployment!  
**Status**: All files prepared and committed to Git  
**Next Action**: Follow Step 1 - Install dependencies
