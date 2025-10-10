import { useState } from "react";
import CommonForm from "../common/form";
import { DialogContent } from "../ui/dialog";
import { Label } from "../ui/label";
import { Separator } from "../ui/separator";

export default function AdminOrdersDetailsView() {
  const initialFormData = {
    status: "",
  };
  const handleOrderStatus = (e) => {
    e.preventDefault();
  }
  const [formData, setFormData] = useState(initialFormData);
  return (
    <DialogContent className="sm:max-w-[600px]">
      <div className="grid gap-6">
        <div className="grid gap-2">
          <div className="flex mt-6 items-center justify-between">
            <p className="font-medium">Order ID:</p>
            <Label>123654</Label>
          </div>
          <div className="flex mt-2 items-center justify-between">
            <p className="font-medium">Order Date:</p>
            <Label>2023-10-01</Label>
          </div>
          <div className="flex mt-2 items-center justify-between">
            <p className="font-medium">Order Status:</p>
            <Label>Shipped</Label>
          </div>
          <div className="flex mt-2 items-center justify-between">
            <p className="font-medium">Order Price:</p>
            <Label>$99.99</Label>
          </div>
        </div>
        <Separator />
        <div className="grid gap-4 ">
          <div className="grid gap-2">
            <div className="font-medium">Order Details</div>
            <ul className="grid gap-3">
              <li className="flex items-center justify-between">
                <span>Product one</span>
                <span>$99.99</span>
              </li>
            </ul>
          </div>
        </div>
        <div className="grid gap-4 ">
          <div className="grid gap-2">
            <div className="font-medium">Shipping Details</div>
            <div className="grid gap-0.5 text-muted-foreground">
              <span>John Doe</span>
              <span>Address</span>
              <span>City</span>
              <span>Pincode</span>
              <span>Phone</span>
              <span>Notes</span>
            </div>
          </div>
        </div>
        <div>
          <CommonForm
            formControls={[
              {
                label: "Order Status",
                name: "status",
                componentType: "select",
                options: [
                  { id: "inProcess", label: "In Process" },
                  { id: "shipped", label: "Shipped" },
                  { id: "delivered", label: "Delivered" },
                  { id: "returned", label: "Returned" },
                  { id: "cancelled", label: "Cancelled" },
                  { id: "pending", label: "Refunded" },
                ],
              },
            ]}
            formData={formData}
            setFormData={setFormData}
            buttonText='Update Order Status'
            onSubmit={handleOrderStatus}
          ></CommonForm>
        </div>
      </div>
    </DialogContent>
  );
}
