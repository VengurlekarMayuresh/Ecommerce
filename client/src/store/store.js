import { configureStore } from "@reduxjs/toolkit";
import authReducer from "./auth-slice/index"
import AdminProductSlice from "./admin/products-slice/index"
import shoppingProductSlice from "./shop/products-slice/index"
import cartSlice from "./shop/cart-slice/index"
const store = configureStore({
    reducer:{
        auth:authReducer,
        adminProducts:AdminProductSlice,
        shoppingProducts: shoppingProductSlice,
        cart: cartSlice
    }
})

export default store;