import axios from "axios";

// const { createSlice, createAsyncThunk } = require("@reduxjs/toolkit");
import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
const initialState = {
  approvalURL: null,
  isLoading: false,
  orderId: null,
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
  },
});

export default shoppingOrderSlice.reducer;
