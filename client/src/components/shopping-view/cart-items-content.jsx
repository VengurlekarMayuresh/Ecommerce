export default function UserCartItemContent({cartItem} ) {
  return <div>{cartItem.title} <br />
  {cartItem.quantity} x ${cartItem.price}
  </div>;
}
