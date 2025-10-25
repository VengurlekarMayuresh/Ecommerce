const { 
  sendOrderPlacedNotification, 
  sendOrderShippedNotification, 
  sendOrderDeliveredNotification,
  sendOrderCancelledNotification 
} = require('../config/azure-communication');

const { 
  sendOrderStatusPushNotification 
} = require('../config/azure-notification-hub');

// Combined notification service (Email + Push)
async function sendOrderNotification(order, customer, status, additionalData = {}) {
  const notifications = [];

  try {
    switch (status) {
      case 'placed':
        // Send email
        const emailPlaced = await sendOrderPlacedNotification(order, customer);
        notifications.push({ type: 'email', ...emailPlaced });

        // Send push notification
        const pushPlaced = await sendOrderStatusPushNotification(customer._id, order.orderId, 'placed');
        notifications.push({ type: 'push', ...pushPlaced });
        break;

      case 'shipped':
        // Send email with tracking
        const emailShipped = await sendOrderShippedNotification(order, customer, additionalData.trackingNumber);
        notifications.push({ type: 'email', ...emailShipped });

        // Send push notification
        const pushShipped = await sendOrderStatusPushNotification(customer._id, order.orderId, 'shipped');
        notifications.push({ type: 'push', ...pushShipped });
        break;

      case 'delivered':
        // Send email
        const emailDelivered = await sendOrderDeliveredNotification(order, customer);
        notifications.push({ type: 'email', ...emailDelivered });

        // Send push notification
        const pushDelivered = await sendOrderStatusPushNotification(customer._id, order.orderId, 'delivered');
        notifications.push({ type: 'push', ...pushDelivered });
        break;

      case 'cancelled':
        // Send email with reason
        const emailCancelled = await sendOrderCancelledNotification(order, customer, additionalData.reason);
        notifications.push({ type: 'email', ...emailCancelled });

        // Send push notification
        const pushCancelled = await sendOrderStatusPushNotification(customer._id, order.orderId, 'cancelled');
        notifications.push({ type: 'push', ...pushCancelled });
        break;

      default:
        console.warn(`Unknown order status: ${status}`);
    }

    return {
      success: true,
      notifications: notifications
    };
  } catch (error) {
    console.error('Error sending notifications:', error);
    return {
      success: false,
      error: error.message,
      notifications: notifications
    };
  }
}

// Middleware to automatically send notifications on order updates
function autoNotifyOrderUpdate(req, res, next) {
  // Store original res.json
  const originalJson = res.json.bind(res);

  // Override res.json
  res.json = function(data) {
    // Check if this is an order update response
    if (data.success && data.order && req.notificationEnabled) {
      const order = data.order;
      const customer = req.customer || order.userId; // Should be populated from DB
      const status = req.orderStatus;
      const additionalData = req.notificationData || {};

      // Send notifications asynchronously (don't wait)
      sendOrderNotification(order, customer, status, additionalData)
        .then(result => {
          console.log('Notifications sent:', result);
        })
        .catch(error => {
          console.error('Failed to send notifications:', error);
        });
    }

    // Call original res.json
    return originalJson(data);
  };

  next();
}

module.exports = {
  sendOrderNotification,
  autoNotifyOrderUpdate
};
