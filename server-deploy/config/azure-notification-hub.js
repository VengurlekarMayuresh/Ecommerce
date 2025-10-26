const azure = require('azure-sb');

let notificationHubService;

// Initialize Azure Notification Hubs
function initializeNotificationHub() {
  const connectionString = process.env.AZURE_NOTIFICATION_HUB_CONNECTION_STRING;
  const hubName = process.env.AZURE_NOTIFICATION_HUB_NAME;
  
  if (!connectionString || !hubName) {
    console.warn('Notification Hub not configured. Push notifications disabled.');
    return false;
  }

  try {
    notificationHubService = azure.createNotificationHubService(hubName, connectionString);
    console.log('Azure Notification Hub initialized successfully');
    return true;
  } catch (error) {
    console.error('Failed to initialize Notification Hub:', error.message);
    return false;
  }
}

// Send push notification to specific user
async function sendPushNotification(userId, title, message, data = {}) {
  if (!notificationHubService) {
    console.warn('Notification Hub not initialized. Skipping push notification.');
    return { success: false, message: 'Push notifications not configured' };
  }

  return new Promise((resolve, reject) => {
    // Prepare notification payload for different platforms
    const payload = {
      data: {
        title: title,
        body: message,
        ...data
      }
    };

    // Send to tagged user (tag = userId)
    const tags = `userId:${userId}`;

    // FCM (Android) notification
    const fcmPayload = JSON.stringify({
      notification: {
        title: title,
        body: message,
      },
      data: data
    });

    notificationHubService.fcm.send(tags, fcmPayload, (error, result) => {
      if (error) {
        console.error('Error sending push notification:', error);
        resolve({ success: false, error: error.message });
      } else {
        console.log('Push notification sent successfully:', result);
        resolve({ success: true, result });
      }
    });
  });
}

// Send notification to multiple users
async function sendBulkPushNotification(userIds, title, message, data = {}) {
  if (!notificationHubService) {
    return { success: false, message: 'Push notifications not configured' };
  }

  const tags = userIds.map(id => `userId:${id}`).join(' || ');
  
  return new Promise((resolve, reject) => {
    const fcmPayload = JSON.stringify({
      notification: {
        title: title,
        body: message,
      },
      data: data
    });

    notificationHubService.fcm.send(tags, fcmPayload, (error, result) => {
      if (error) {
        console.error('Error sending bulk push notification:', error);
        resolve({ success: false, error: error.message });
      } else {
        console.log('Bulk push notification sent successfully');
        resolve({ success: true, result });
      }
    });
  });
}

// Send to all users (broadcast)
async function sendBroadcastNotification(title, message, data = {}) {
  if (!notificationHubService) {
    return { success: false, message: 'Push notifications not configured' };
  }

  return new Promise((resolve, reject) => {
    const fcmPayload = JSON.stringify({
      notification: {
        title: title,
        body: message,
      },
      data: data
    });

    notificationHubService.fcm.send(null, fcmPayload, (error, result) => {
      if (error) {
        console.error('Error sending broadcast notification:', error);
        resolve({ success: false, error: error.message });
      } else {
        console.log('Broadcast notification sent successfully');
        resolve({ success: true, result });
      }
    });
  });
}

// Register device for push notifications
async function registerDevice(userId, deviceToken, platform = 'fcm') {
  if (!notificationHubService) {
    return { success: false, message: 'Push notifications not configured' };
  }

  return new Promise((resolve, reject) => {
    const tags = [`userId:${userId}`];

    if (platform === 'fcm') {
      notificationHubService.fcm.createNativeRegistration(deviceToken, tags, (error, registration) => {
        if (error) {
          console.error('Error registering device:', error);
          resolve({ success: false, error: error.message });
        } else {
          console.log('Device registered successfully:', registration.RegistrationId);
          resolve({ success: true, registrationId: registration.RegistrationId });
        }
      });
    } else {
      resolve({ success: false, message: 'Platform not supported' });
    }
  });
}

// Order-specific push notifications
async function sendOrderStatusPushNotification(userId, orderId, status) {
  const notifications = {
    placed: {
      title: '🎉 Order Placed!',
      message: `Your order #${orderId} has been confirmed.`,
      data: { orderId, status: 'placed', type: 'order_update' }
    },
    shipped: {
      title: '📦 Order Shipped!',
      message: `Your order #${orderId} is on the way!`,
      data: { orderId, status: 'shipped', type: 'order_update' }
    },
    delivered: {
      title: '✅ Order Delivered!',
      message: `Your order #${orderId} has been delivered successfully.`,
      data: { orderId, status: 'delivered', type: 'order_update' }
    },
    cancelled: {
      title: '❌ Order Cancelled',
      message: `Your order #${orderId} has been cancelled.`,
      data: { orderId, status: 'cancelled', type: 'order_update' }
    }
  };

  const notification = notifications[status];
  if (!notification) {
    return { success: false, message: 'Invalid order status' };
  }

  return await sendPushNotification(userId, notification.title, notification.message, notification.data);
}

module.exports = {
  initializeNotificationHub,
  sendPushNotification,
  sendBulkPushNotification,
  sendBroadcastNotification,
  registerDevice,
  sendOrderStatusPushNotification
};
