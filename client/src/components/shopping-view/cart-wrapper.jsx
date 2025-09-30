import { SheetContent, SheetHeader, SheetTitle } from "../ui/sheet";
import { Button } from "../ui/button";
import UserCartItemContent from "./cart-items-content";

function UserCartWrapper({ cartItems }) {
  console.log(cartItems, "cart items in cart wrapper");

  return (
    <SheetContent className="sm:max-w-md">
      <SheetHeader>
        <SheetTitle>Your cart</SheetTitle>
      </SheetHeader>

      <div className="mt-8 space-y-4">
        {cartItems && cartItems.length > 0 ? (
          cartItems.map((item) => <UserCartItemContent cartItem={item} key={item.productId} />)
        ) : (
          <div>No items in cart</div>
        )}
      </div>

      <div className="mt-8 space-y-4">
        <div className="mx-4 flex justify-between">
          <span className="font-bold">Total</span>
          <span className="font-bold">$0.00</span>
        </div>
      </div>

      <Button className="mt-4 mx-4">Checkout</Button>
    </SheetContent>
  );
}

export default UserCartWrapper;
