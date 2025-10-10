import React from "react";
import img from "../../assets/image.png";
import Address from "@/components/shopping-view/address";
import { useSelector } from "react-redux";
import UserCartItemContent from "@/components/shopping-view/cart-items-content";
import { Button } from "@/components/ui/button";

export default function ShoppingCheckoutPage() {
  const {cartItems} = useSelector((state) => state.shoppingCart);

  const totalAmount =
    cartItems && cartItems.length > 0
      ? cartItems.reduce((total, item) => {
          const itemPrice = item.salesPrice > 0 ? item.salesPrice : item.price;
          return total + itemPrice * item.quantity;
        }, 0)
      : 0;

return <div className="flex flex-col">
    <div className="relative h-[300px] w-full overflow-hidden">
      <img src={img} alt="Checkout Banner" className="object-cover object-center w-full h-full" />
    </div>
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-5  mt-5 p-5 ">
      <Address/>
      <div className="flex flex-col gap-3">
        {
          cartItems ? cartItems.map((item) => <UserCartItemContent cartItem={item} key={item._id}/>): <h1 className="text-2xl font-semibold">No items in cart</h1>

        }
    
      <div className="mt-8 space-y-4">
            <div className="mx-4 flex justify-between">
              <span className="font-bold">Total</span>
              <span className="font-bold">${totalAmount.toFixed(2)}</span>
            </div>
          </div>
        <div className="mt-4 w-full">
            <Button className='w-full'>CheckOut with PayPal</Button>
        </div>
            </div>
    </div>
  </div>
}
