const Order = require("../../models/Order");


const getAllOrdersOfAllUsers = async (req, res) => {
  try {
    const orders = await Order.find({});
    if (!orders) {
      return res
        .status(404)
        .json({ message: "Orders not found", success: false });
    }
    res
      .status(200)
      .json({ message: "Orders fetched", data: orders, success: true });

  } catch (error) {
    console.error("Error fetching orders:", error);
    res.status(500).json({ message: "Internal server error", success: false });
  }
}

const getOrderDetailsForAdmin = async (req, res) => {
  try {
    const { id } = req.params;
    const order = await Order.findById(id);
    if (!order) {
      return res
        .status(404)
        .json({ message: "Order not found", success: false });
    }
    res
      .status(200)
      .json({ message: "Order fetched", data: order, success: true });
  } catch (error) {
    console.error("Error fetching order:", error);
    res.status(500).json({ message: "Internal server error", success: false });
  }
}

const updateOrderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { orderStatus } = req.body;

    const order = await Order.findById(id);
    if (!order) {
      return res
        .status(404)
        .json({ message: "Order not found", success: false });
    }
      await Order.findByIdAndUpdate(id, { orderStatus: orderStatus });
      res
        .status(200)
        .json({ message: "Order status updated", success: true });

  } catch (error) {
    res.status(500).json({ message: "Internal server error", success: false });
  }
}

module.exports = {
  getAllOrdersOfAllUsers,
  getOrderDetailsForAdmin,
  updateOrderStatus

};