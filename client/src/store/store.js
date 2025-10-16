import { configureStore } from "@reduxjs/toolkit";
import authReducer from "./auth-slice/index"
import AdminProductSlice from "./admin/products-slice/index"
import shoppingProductSlice from "./shop/products-slice/index"
import shoppingCart from "./shop/cart-slice/index"
import shopAddressSlice from "./shop/address-slice/index"
import shopOrderSlice from "./shop/order-slice/index"
import adminOrderSlice from "./admin/order-slice/index"
import shopSearchSlice from "./shop/search-slice/index"
import shopReviewSlice from "./shop/review-slice/index"
const store = configureStore({
    reducer:{
        auth:authReducer,
        adminProducts:AdminProductSlice,
        adminOrder: adminOrderSlice,
        shoppingProducts: shoppingProductSlice,
        shoppingCart: shoppingCart,
        shopAddress: shopAddressSlice,
        shoppingOrder: shopOrderSlice,
        shopSearch: shopSearchSlice,
        shopReview: shopReviewSlice,
    }
})

export default store;