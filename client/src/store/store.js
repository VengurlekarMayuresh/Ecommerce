import { configureStore } from "@reduxjs/toolkit";
import authReducer from "./auth-slice/index"
import AdminProductSlice from "./admin/products-slice/index"
const store = configureStore({
    reducer:{
        auth:authReducer,
        adminProducts:AdminProductSlice,
    }
})

export default store;