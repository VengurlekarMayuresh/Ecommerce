const paypal = require("../../helpers/paypal");
const Order = require("../../models/Order");
const Address = require("../../models/Address");
const Cart = require("../../models/Cart");

const createOrder = async (req, res) => {
  try {
    const {
      userId,
      cartId,
      cartItems,
      addressInfo,
      orderStatus,
      paymentMethod,
      paymentStatus,
      totalAmount,
      orderDate,
      orderUpdateDate,
      paymentId,
      payerId,
    } = req.body;

    const create_payment_json = {
      intent: "sale",
      payer: {
        payment_method: "paypal",
      },
      redirect_urls: {
        return_url: "http://localhost:5173/shop/paypal-return",
        cancel_url: "http://localhost:5173/shop/paypal-cancel",
      },
      transactions: [
        {
          item_list: {
            items: cartItems.map((item) => ({
              name: item.title,
              sku: item.productId,
              price: item.salePrice
                ? item.salePrice.toFixed(2)
                : item.price.toFixed(2),
              currency: "USD",
              quantity: item.quantity,
            })),
          },
          amount: {
            currency: "USD",
            total: totalAmount.toFixed(2),
          },
          description: "Order Description",
        },
      ],
    };

    paypal.payment.create(create_payment_json, async function (error, payment) {
      if (error) {
        console.error(error);
        res
          .status(500)
          .json({ message: "Error creating PayPal payment", success: false });
      } else {
        const newOrder = new Order({
          userId,
          cartId,
          cartItems,
          addressInfo,
          orderStatus,
          paymentMethod,
          paymentStatus,
          totalAmount,
          orderDate,
          orderUpdateDate,
          paymentId,
          payerId,
        });

        await newOrder.save();

        const approvalURL = payment.links.find(
          (link) => link.rel === "approval_url"
        ).href;

        res.status(200).json({
          message: "Order created successfully",
          success: true,
          approvalURL,
          orderId: newOrder._id,
        });
      }
    });
  } catch (error) {
    console.error("Error creating order:", error);
    res.status(500).json({ message: "Internal server error", success: false });
  }
};

const capturePayment = async (req, res) => {
  try {
    const { paymentId, payerId, orderId } = req.body;
    const order = await Order.findById(orderId);
    if (!order) {
      return res
        .status(404)
        .json({ message: "Order not found", success: false });
    }
    order.paymentStatus = "paid";
    order.orderStatus = "confirmed";
    order.paymentId = paymentId;
    order.payerId = payerId;

    const getCartId = order.cartId;
    const cart = await Cart.findByIdAndDelete(getCartId);

    await order.save();
    res
      .status(200)
      .json({ message: "Order Confirmed", data: order, success: true });
  } catch (error) {
    console.error("Error creating order:", error);
    res.status(500).json({ message: "Internal server error", success: false });
  }
};

const getAllOrders = async (req, res) => {
  try {
    const {userId} = req.params;
    const orders = await Order.find({userId});
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

const getOrderDetails = async (req, res) => {
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
module.exports = {
  createOrder,
  capturePayment,
  getAllOrders,
  getOrderDetails
};
