require("dotenv").config();
const appInsights = require("applicationinsights");
const cookieParser = require("cookie-parser");
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const { initializeBlobStorage, ensureContainerExists } = require("./config/azure-storage");

// Initialize Application Insights first
if (process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
  appInsights.setup(process.env.APPLICATIONINSIGHTS_CONNECTION_STRING)
    .setAutoDependencyCorrelation(true)
    .setAutoCollectRequests(true)
    .setAutoCollectPerformance(true, true)
    .setAutoCollectExceptions(true)
    .setAutoCollectDependencies(true)
    .setAutoCollectConsole(true)
    .setUseDiskRetryCaching(true)
    .setSendLiveMetrics(true)
    .setDistributedTracingMode(appInsights.DistributedTracingModes.AI_AND_W3C);
  appInsights.start();
  console.log("Application Insights initialized");
}

const authRouter = require("./routes/auth/auth-routes");
const adminProductRouter = require("./routes/admin/products-routes");
const shopProductRouter = require("./routes/shop/products-routes");
const cartRouter = require("./routes/shop/cart-routes");
const shopAddressRouter = require("./routes/shop/address-routes");
const shopOrderRouter = require("./routes/shop/order-routes");
const adminOrderRouter = require("./routes/admin/order-routes");
const shopSearchRouter = require("./routes/shop/search-routes");
const reviewRouter = require("./routes/shop/review-routes");
const commonFeatureRouter = require("./routes/common/feature-routes");

const app = express();

// CORS configuration for Azure
app.use(
  cors({
    origin: process.env.CLIENT_URL || "http://localhost:5173",
    methods: ["GET", "POST", "PUT", "DELETE"],
    allowedHeaders: [
      "Content-Type",
      "Authorization",
      "Cache-Control",
      "Expires",
      "Pragma",
    ],
    credentials: true,
  })
);

app.use(cookieParser());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`);
  next();
});

// Routes
app.use("/api/auth", authRouter);
app.use("/api/admin/products", adminProductRouter);
app.use("/api/admin/orders", adminOrderRouter);
app.use("/api/shop/products", shopProductRouter);
app.use("/api/shop/cart", cartRouter);
app.use("/api/shop/address", shopAddressRouter);
app.use('/api/shop/order', shopOrderRouter);
app.use('/api/shop/search', shopSearchRouter);
app.use('/api/shop/review', reviewRouter);
app.use('/api/common/feature', commonFeatureRouter);

// Health check endpoint for Azure
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    azureStorage: process.env.AZURE_STORAGE_CONNECTION_STRING ? 'configured' : 'not configured',
    appInsights: process.env.APPLICATIONINSIGHTS_CONNECTION_STRING ? 'enabled' : 'disabled'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'E-commerce API is running',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  if (appInsights.defaultClient) {
    appInsights.defaultClient.trackException({ exception: err });
  }
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error'
  });
});

// Initialize Azure Blob Storage
initializeBlobStorage();
ensureContainerExists().catch(err => console.error('Container setup failed:', err));

// Database connection
mongoose
  .connect(process.env.MONGO_DBURL, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => {
    console.log("MongoDB connected successfully");
    if (appInsights.defaultClient) {
      appInsights.defaultClient.trackEvent({ name: 'DatabaseConnected' });
    }
  })
  .catch((err) => {
    console.error("MongoDB connection error:", err);
    if (appInsights.defaultClient) {
      appInsights.defaultClient.trackException({ exception: err });
    }
  });

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  mongoose.connection.close();
  if (appInsights.defaultClient) {
    appInsights.defaultClient.flush();
  }
  process.exit(0);
});

const PORT = process.env.PORT || 8080;

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  if (appInsights.defaultClient) {
    appInsights.defaultClient.trackEvent({ name: 'ServerStarted', properties: { port: PORT } });
  }
});

module.exports = app;
