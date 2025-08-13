import { Route, Routes } from "react-router-dom";
import "./App.css";
import AuthLayout from "./components/auth/layout";
import AuthLogin from "./pages/auth/login";
import AuthRegister from "./pages/auth/register";
import AdminLayout from "./components/admin-view/admin-layout";
import AdminDashboard from "./pages/admin-view/dashboard";
import AdminProducts from "./pages/admin-view/products";
import AdminOrders from "./pages/admin-view/orders";
import AdminFeatures from "./pages/admin-view/features";
import ShoppingLayout from "./components/shopping-view/shopping-layout";
import PageNotFound from "./pages/not-found/PageNotFound";
import ShoppingAccount from "./pages/shopping-view/account";
import ShoppingCheckoutPage from "./pages/shopping-view/checkoutpage";
import ShoppingHome from "./pages/shopping-view/home";
import ShoppingListings from "./pages/shopping-view/listings";
import CheckAuth from "./components/common/check-auth";
import UnAuthPage from "./pages/un-auth-page/UnAuthPage";
import { useDispatch, useSelector } from "react-redux";
import { useEffect } from "react";
import { checkAuth } from "@/store/auth-slice";

function App() {
  const { isAuthenticated, user } = useSelector((state) => state.auth);
  const dispatch = useDispatch();
  useEffect(() => {
    dispatch(checkAuth());
  }, [dispatch]);
  return (
    <div className="flex flex-col overflow-hidden bg-white">
      {/*Auth Routes */}
      <Routes>
        <Route
          path="/auth"
          element={
            <CheckAuth isAuthenticated={isAuthenticated} user={user}>
              <AuthLayout />
            </CheckAuth>
          }
        >
          <Route path="login" element={<AuthLogin />} />
          <Route path="register" element={<AuthRegister />} />
        </Route>

        {/*Admin Routes */}
        <Route
          path="/admin"
          element={
            <CheckAuth isAuthenticated={isAuthenticated} user={user}>
              <AdminLayout />
            </CheckAuth>
          }
        >
          <Route path="dashboard" element={<AdminDashboard />} />
          <Route path="products" element={<AdminProducts />} />
          <Route path="orders" element={<AdminOrders />} />
          <Route path="features" element={<AdminFeatures />} />
        </Route>

        {/*Shopping Routes */}
        <Route
          path="/shop"
          element={
            <CheckAuth isAuthenticated={isAuthenticated} user={user}>
              <ShoppingLayout />
            </CheckAuth>
          }
        >
          <Route path="home" element={<ShoppingHome />} />
          <Route path="account" element={<ShoppingAccount />} />
          <Route path="checkoutpage" element={<ShoppingCheckoutPage />} />
          <Route path="listings" element={<ShoppingListings />} />
        </Route>

        {/*Page Note Found */}
        <Route path="*" element={<PageNotFound />} />
        <Route path="/un-auth-page" element={<UnAuthPage />} />
      </Routes>
    </div>
  );
}

export default App;
