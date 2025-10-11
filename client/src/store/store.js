import { configureStore } from "@reduxjs/toolkit";
import authReducer from "./auth-slice/index"
import AdminProductSlice from "./admin/products-slice/index"
import shoppingProductSlice from "./shop/products-slice/index"
import cartSlice from "./shop/cart-slice/index"
import shopAddressSlice from "./shop/address-slice/index"
import shopOrderSlice from "./shop/order-slice/index"
const store = configureStore({
    reducer:{
        auth:authReducer,
        adminProducts:AdminProductSlice,
        shoppingProducts: shoppingProductSlice,
        shoppingCart: cartSlice,
        shopAddress: shopAddressSlice,
        shopOrder: shopOrderSlice
    }
})

export default store;