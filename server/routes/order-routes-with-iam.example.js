const express = require('express');
const router = express.Router();

// Import IAM middleware
const { 
  requireAdmin, 
  requireCustomer, 
  requireAdminOrOwn 
} = require('../config/azure-ad-b2c');

// Import notification middleware
const { 
  autoNotifyOrderUpdate,
  sendOrderNotification 
} = require('../middleware/notification-middleware');

// Example: Place order (Customer only)
// POST /api/orders
router.post('/', 
  requireCustomer, // Only customers can place orders
  autoNotifyOrderUpdate, // Auto-send notifications
  async (req, res) => {
    try {
      const userId = req.user.userId; // From Azure AD B2C token
      const { cartItems, addressInfo, paymentInfo } = req.body;

      // Create order logic here
      const order = {
        orderId: `ORD-${Date.now()}`,
        userId: userId,
        cartItems: cartItems,
        addressInfo: addressInfo,
        totalAmount: calculateTotal(cartItems),
        orderDate: new Date(),
        orderStatus: 'pending',
        paymentStatus: 'pending'
      };

      // Save order to database
      // const savedOrder = await Order.create(order);

      // Enable notifications
      req.notificationEnabled = true;
      req.orderStatus = 'placed';
      req.customer = { 
        _id: userId, 
        userName: req.user.name, 
        email: req.user.email 
      };

      res.json({
        success: true,
        message: 'Order placed successfully',
        order: order
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to place order',
        error: error.message
      });
    }
  }
);

// Example: Get all orders (Admin only)
// GET /api/orders/all
router.get('/all', 
  requireAdmin, // Only admins can view all orders
  async (req, res) => {
    try {
      // Fetch all orders from database
      // const orders = await Order.find().populate('userId');

      res.json({
        success: true,
        orders: [] // Replace with actual orders
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to fetch orders',
        error: error.message
      });
    }
  }
);

// Example: Get user's own orders (Customer can view their own, Admin can view any)
// GET /api/orders/:userId
router.get('/:userId', 
  requireAdminOrOwn('userId'), // Admin or owner can access
  async (req, res) => {
    try {
      const userId = req.params.userId;

      // Fetch orders for specific user
      // const orders = await Order.find({ userId: userId });

      res.json({
        success: true,
        orders: [], // Replace with actual orders
        isAdmin: req.isAdmin
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to fetch orders',
        error: error.message
      });
    }
  }
);

// Example: Update order status (Admin only)
// PUT /api/orders/:orderId/status
router.put('/:orderId/status', 
  requireAdmin, // Only admins can update order status
  autoNotifyOrderUpdate, // Auto-send notifications
  async (req, res) => {
    try {
      const { orderId } = req.params;
      const { status, trackingNumber, reason } = req.body;

      // Update order in database
      // const order = await Order.findOne({ orderId: orderId }).populate('userId');
      // order.orderStatus = status;
      // await order.save();

      // Mock order for example
      const order = {
        orderId: orderId,
        orderStatus: status,
        userId: 'user123'
      };

      // Mock customer for example
      const customer = {
        _id: 'user123',
        userName: 'John Doe',
        email: 'john@example.com'
      };

      // Enable notifications
      req.notificationEnabled = true;
      req.orderStatus = status;
      req.customer = customer;
      req.notificationData = { trackingNumber, reason };

      res.json({
        success: true,
        message: 'Order status updated successfully',
        order: order
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to update order status',
        error: error.message
      });
    }
  }
);

// Example: Cancel order (Admin or order owner)
// DELETE /api/orders/:orderId
router.delete('/:orderId', 
  requireAdminOrOwn('userId'), // Admin or owner can cancel
  autoNotifyOrderUpdate,
  async (req, res) => {
    try {
      const { orderId } = req.params;
      const { reason } = req.body;

      // Update order status to cancelled
      // const order = await Order.findOne({ orderId: orderId }).populate('userId');
      // order.orderStatus = 'cancelled';
      // await order.save();

      // Mock data
      const order = { orderId: orderId, orderStatus: 'cancelled' };
      const customer = { 
        _id: req.user.userId, 
        userName: req.user.name, 
        email: req.user.email 
      };

      // Enable notifications
      req.notificationEnabled = true;
      req.orderStatus = 'cancelled';
      req.customer = customer;
      req.notificationData = { reason };

      res.json({
        success: true,
        message: 'Order cancelled successfully',
        order: order
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to cancel order',
        error: error.message
      });
    }
  }
);

// Helper function
function calculateTotal(items) {
  return items.reduce((total, item) => total + (item.price * item.quantity), 0);
}

module.exports = router;
