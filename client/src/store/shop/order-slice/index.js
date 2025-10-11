import axios from "axios";

// const { createSlice, createAsyncThunk } = require("@reduxjs/toolkit");
import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
const initialState = {
  approvalURL: null,
  isLoading: false,
  orderId: null,
  orderList: [],
  orderDetails: null,
};

export const createNewOrder = createAsyncThunk(
  "/order/create",
  async (orderData) => {
    const response = await axios.post(
      "http://localhost:5000/api/shop/order/create",
      orderData
    );
    return response.data;
  }
);

export const capturePayment = createAsyncThunk(
  "/order/capture",
  async ({ paymentId, payerId, orderId }) => {
    const response = await axios.post(
      "http://localhost:5000/api/shop/order/capture",
      { paymentId, payerId, orderId }
    );
    return response.data;
  }
);

export const getAllOrders = createAsyncThunk("/all/orders", async (userId) => {
  const response = await axios.get(
    `http://localhost:5000/api/shop/order/list/${userId}`
  );
  return response.data;
});

export const getOrderDetails = createAsyncThunk(
  "/order/details",
  async (id) => {
    const response = await axios.get(
      `http://localhost:5000/api/shop/order/details/${id}`
    );
    return response.data;
  }
);

const shoppingOrderSlice = createSlice({
  name: "shoppingOrder",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder.addCase(createNewOrder.pending, (state) => {
      state.isLoading = true;
    });
    builder.addCase(createNewOrder.fulfilled, (state, action) => {
      state.isLoading = false;
      state.approvalURL = action.payload.approvalURL;
      state.orderId = action.payload.orderId;
      sessionStorage.setItem(
        "currentOrderId",
        JSON.stringify(action.payload.orderId)
      );
    });
    builder.addCase(createNewOrder.rejected, (state) => {
      state.isLoading = false;
      state.approvalURL = null;
      state.orderId = null;
    });
    builder.addCase(getAllOrders.pending, (state) => {
      state.isLoading = true;
    });
    builder.addCase(getAllOrders.fulfilled, (state, action) => {
      state.isLoading = false;
      state.orderList = action.payload.data;
    });
    builder.addCase(getAllOrders.rejected, (state) => {
      state.isLoading = false;
      state.orderList = [];
    });
    builder.addCase(getOrderDetails.pending, (state) => {
      state.isLoading = true;
    });
    builder.addCase(getOrderDetails.fulfilled, (state, action) => {
      state.isLoading = false;
      state.orderDetails = action.payload.data;
    });
    builder.addCase(getOrderDetails.rejected, (state) => {
      state.isLoading = false;
      state.orderDetails = null;
    });
  },
});

export default shoppingOrderSlice.reducer;
