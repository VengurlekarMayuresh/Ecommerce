const { EmailClient } = require("@azure/communication-email");

let emailClient;

// Initialize Azure Communication Services Email Client
function initializeCommunicationServices() {
  const connectionString = process.env.AZURE_COMMUNICATION_CONNECTION_STRING;
  
  if (!connectionString) {
    console.warn('Azure Communication Services connection string not set. Email notifications disabled.');
    return false;
  }

  try {
    emailClient = new EmailClient(connectionString);
    console.log('Azure Communication Services initialized successfully');
    return true;
  } catch (error) {
    console.error('Failed to initialize Azure Communication Services:', error.message);
    return false;
  }
}

// Order status notification templates
const emailTemplates = {
  orderPlaced: (order, customer) => ({
    subject: `Order Confirmation #${order.orderId}`,
    html: `
      <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #4CAF50; color: white; padding: 20px; text-align: center;">
            <h1>Order Confirmed!</h1>
          </div>
          <div style="padding: 20px;">
            <p>Hi ${customer.userName},</p>
            <p>Thank you for your order! We're processing it now.</p>
            
            <div style="background-color: #f5f5f5; padding: 15px; margin: 20px 0; border-radius: 5px;">
              <h3>Order Details:</h3>
              <p><strong>Order ID:</strong> ${order.orderId}</p>
              <p><strong>Total Amount:</strong> $${order.totalAmount}</p>
              <p><strong>Order Date:</strong> ${new Date(order.orderDate).toLocaleDateString()}</p>
            </div>

            <h3>Items Ordered:</h3>
            <ul>
              ${order.cartItems.map(item => `
                <li>${item.title} - Quantity: ${item.quantity} - $${item.price}</li>
              `).join('')}
            </ul>

            <div style="background-color: #e3f2fd; padding: 15px; margin: 20px 0; border-radius: 5px;">
              <h3>Shipping Address:</h3>
              <p>${order.addressInfo.address}</p>
              <p>${order.addressInfo.city}, ${order.addressInfo.pincode}</p>
              <p>${order.addressInfo.phone}</p>
            </div>

            <p>We'll notify you when your order ships.</p>
            <p>Best regards,<br>E-Commerce Team</p>
          </div>
          <div style="background-color: #f5f5f5; padding: 15px; text-align: center; font-size: 12px;">
            <p>Questions? Contact us at support@ecommerce.com</p>
          </div>
        </body>
      </html>
    `
  }),

  orderShipped: (order, customer, trackingNumber) => ({
    subject: `Your Order #${order.orderId} Has Shipped! 📦`,
    html: `
      <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #2196F3; color: white; padding: 20px; text-align: center;">
            <h1>Your Order is On the Way!</h1>
          </div>
          <div style="padding: 20px;">
            <p>Hi ${customer.userName},</p>
            <p>Great news! Your order has been shipped and is on its way to you.</p>
            
            <div style="background-color: #f5f5f5; padding: 15px; margin: 20px 0; border-radius: 5px;">
              <p><strong>Order ID:</strong> ${order.orderId}</p>
              <p><strong>Tracking Number:</strong> ${trackingNumber || 'Will be updated soon'}</p>
              <p><strong>Estimated Delivery:</strong> 3-5 business days</p>
            </div>

            <div style="text-align: center; margin: 30px 0;">
              <a href="#" style="background-color: #2196F3; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
                Track Your Order
              </a>
            </div>

            <p>Your package is being carefully handled and will arrive soon!</p>
            <p>Best regards,<br>E-Commerce Team</p>
          </div>
        </body>
      </html>
    `
  }),

  orderDelivered: (order, customer) => ({
    subject: `Your Order #${order.orderId} Has Been Delivered! ✅`,
    html: `
      <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #4CAF50; color: white; padding: 20px; text-align: center;">
            <h1>Order Delivered Successfully!</h1>
          </div>
          <div style="padding: 20px;">
            <p>Hi ${customer.userName},</p>
            <p>Your order has been successfully delivered!</p>
            
            <div style="background-color: #f5f5f5; padding: 15px; margin: 20px 0; border-radius: 5px;">
              <p><strong>Order ID:</strong> ${order.orderId}</p>
              <p><strong>Delivered On:</strong> ${new Date().toLocaleDateString()}</p>
            </div>

            <p>We hope you love your purchase! If you have any issues, please contact our support team.</p>

            <div style="text-align: center; margin: 30px 0;">
              <a href="#" style="background-color: #FF9800; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
                Leave a Review
              </a>
            </div>

            <p>Thank you for shopping with us!</p>
            <p>Best regards,<br>E-Commerce Team</p>
          </div>
        </body>
      </html>
    `
  }),

  orderCancelled: (order, customer, reason) => ({
    subject: `Order #${order.orderId} Cancelled`,
    html: `
      <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #f44336; color: white; padding: 20px; text-align: center;">
            <h1>Order Cancelled</h1>
          </div>
          <div style="padding: 20px;">
            <p>Hi ${customer.userName},</p>
            <p>Your order #${order.orderId} has been cancelled.</p>
            
            ${reason ? `<p><strong>Reason:</strong> ${reason}</p>` : ''}

            <div style="background-color: #f5f5f5; padding: 15px; margin: 20px 0; border-radius: 5px;">
              <p><strong>Refund Status:</strong> Your refund will be processed within 5-7 business days.</p>
              <p><strong>Amount:</strong> $${order.totalAmount}</p>
            </div>

            <p>If you have any questions, please contact our support team.</p>
            <p>Best regards,<br>E-Commerce Team</p>
          </div>
        </body>
      </html>
    `
  }),

  // Admin notification for new orders
  adminNewOrder: (order, customer) => ({
    subject: `New Order Received - #${order.orderId}`,
    html: `
      <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #673AB7; color: white; padding: 20px; text-align: center;">
            <h1>New Order Alert</h1>
          </div>
          <div style="padding: 20px;">
            <h3>Order Details:</h3>
            <p><strong>Order ID:</strong> ${order.orderId}</p>
            <p><strong>Customer:</strong> ${customer.userName} (${customer.email})</p>
            <p><strong>Total Amount:</strong> $${order.totalAmount}</p>
            <p><strong>Payment Status:</strong> ${order.paymentStatus}</p>
            <p><strong>Order Date:</strong> ${new Date(order.orderDate).toLocaleDateString()}</p>

            <h3>Items:</h3>
            <ul>
              ${order.cartItems.map(item => `
                <li>${item.title} - Quantity: ${item.quantity} - $${item.price}</li>
              `).join('')}
            </ul>

            <div style="text-align: center; margin: 30px 0;">
              <a href="#" style="background-color: #673AB7; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
                View Order in Dashboard
              </a>
            </div>
          </div>
        </body>
      </html>
    `
  })
};

// Send email notification
async function sendEmailNotification(recipientEmail, templateName, data) {
  if (!emailClient) {
    console.warn('Email client not initialized. Skipping notification.');
    return { success: false, message: 'Email service not configured' };
  }

  try {
    const template = emailTemplates[templateName];
    if (!template) {
      throw new Error(`Template ${templateName} not found`);
    }

    const emailContent = template(...data);
    const senderAddress = process.env.AZURE_COMMUNICATION_SENDER_ADDRESS;

    if (!senderAddress) {
      throw new Error('Sender email address not configured');
    }

    const message = {
      senderAddress: senderAddress,
      content: {
        subject: emailContent.subject,
        html: emailContent.html,
      },
      recipients: {
        to: [{ address: recipientEmail }],
      },
    };

    const poller = await emailClient.beginSend(message);
    const result = await poller.pollUntilDone();

    console.log(`Email sent successfully to ${recipientEmail}. Message ID: ${result.id}`);
    
    return { 
      success: true, 
      messageId: result.id,
      status: result.status 
    };
  } catch (error) {
    console.error('Error sending email:', error.message);
    return { success: false, error: error.message };
  }
}

// Helper functions for specific notifications
async function sendOrderPlacedNotification(order, customer) {
  // Send to customer
  await sendEmailNotification(customer.email, 'orderPlaced', [order, customer]);
  
  // Send to admin
  const adminEmail = process.env.ADMIN_NOTIFICATION_EMAIL;
  if (adminEmail) {
    await sendEmailNotification(adminEmail, 'adminNewOrder', [order, customer]);
  }
}

async function sendOrderShippedNotification(order, customer, trackingNumber) {
  return await sendEmailNotification(customer.email, 'orderShipped', [order, customer, trackingNumber]);
}

async function sendOrderDeliveredNotification(order, customer) {
  return await sendEmailNotification(customer.email, 'orderDelivered', [order, customer]);
}

async function sendOrderCancelledNotification(order, customer, reason) {
  return await sendEmailNotification(customer.email, 'orderCancelled', [order, customer, reason]);
}

module.exports = {
  initializeCommunicationServices,
  sendEmailNotification,
  sendOrderPlacedNotification,
  sendOrderShippedNotification,
  sendOrderDeliveredNotification,
  sendOrderCancelledNotification
};
