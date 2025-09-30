import { Minus, Plus, Trash } from "lucide-react";
import { Button } from "../ui/button";
import { useDispatch } from "react-redux";
import { deleteCartItems, updateCartItems } from "@/store/shop/cart-slice";
import { useSelector } from "react-redux";
import { toast } from "sonner";

export default function UserCartItemContent({cartItem} ) {
    const dispatch = useDispatch();
    const {user} = useSelector((state) => state.auth);


    function handleCartItemDelete(cartItemId){
        dispatch(deleteCartItems({ userId : user.id , productId :cartItemId})).then(() => {
            toast.success("Item removed from cart");
        });
   
    }
    
    function handleDecreaseQuantity(cartItemId){
        dispatch(updateCartItems({ userId : user.id , productId :cartItemId, quantity: cartItem.quantity - 1})).then(() => {
            toast.success("Cart item updated successfully");
        });
    }
    function handleIncreaseQuantity(cartItemId){
        dispatch(updateCartItems({ userId : user.id , productId :cartItemId, quantity: cartItem.quantity + 1})).then(() => {
            toast.success("Cart item updated successfully");
        });
    }

  return <div className="flex items-center space-x-4">
    <img src={cartItem.image} alt={cartItem.title} className="w-20 h-20  rounded object-cover"/>
    <div className="flex-1">
         <h3 className="font-extrabold">{cartItem.title}</h3>
        <div className="flex items-center mt-1 gap-2">
            <Button disabled={cartItem.quantity === 1} onClick={()=>handleDecreaseQuantity(cartItem.productId)} variant='outline' size="icon" className="h-8 w-8 p-0 rounded-full">
                <Minus className="w-4 h-4"/>
                <span className="sr-only ">Decrease</span>
            </Button>
            <span className="font-semibold">{cartItem.quantity}</span>
               <Button onClick = {()=>handleIncreaseQuantity(cartItem.productId)} variant='outline' size="icon" className="h-8 w-8 p-0 rounded-full">
                <Plus className="w-4 h-4"/>
                   <span className="sr-only ">Increase</span>
               </Button>
        </div>
    </div>
    <div className="flex flex-col items-end">
        <p className="font-semibold">
            ${(cartItem.salesPrice > 0 ? cartItem.salesPrice :cartItem.price) * cartItem.quantity}
        </p>
        <Trash onClick={()=>handleCartItemDelete(cartItem.productId)} className="cursor-pointer mt-1 " size={20}/>
    </div>
  </div>
}
