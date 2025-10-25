const appInsights = require('applicationinsights');

function setupApplicationInsights() {
  const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
  
  if (!connectionString) {
    console.warn('Application Insights connection string not found. Monitoring disabled.');
    return null;
  }

  try {
    appInsights.setup(connectionString)
      .setAutoDependencyCorrelation(true)
      .setAutoCollectRequests(true)
      .setAutoCollectPerformance(true, true)
      .setAutoCollectExceptions(true)
      .setAutoCollectDependencies(true)
      .setAutoCollectConsole(true, true)
      .setUseDiskRetryCaching(true)
      .setSendLiveMetrics(true)
      .setDistributedTracingMode(appInsights.DistributedTracingModes.AI_AND_W3C)
      .start();

    console.log('Application Insights initialized successfully');
    
    return appInsights.defaultClient;
  } catch (error) {
    console.error('Failed to initialize Application Insights:', error.message);
    return null;
  }
}

// Custom tracking helpers
function trackCustomEvent(name, properties = {}) {
  if (appInsights.defaultClient) {
    appInsights.defaultClient.trackEvent({
      name: name,
      properties: properties
    });
  }
}

function trackCustomMetric(name, value) {
  if (appInsights.defaultClient) {
    appInsights.defaultClient.trackMetric({
      name: name,
      value: value
    });
  }
}

module.exports = {
  setupApplicationInsights,
  trackCustomEvent,
  trackCustomMetric,
  client: () => appInsights.defaultClient
};
