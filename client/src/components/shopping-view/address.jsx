import { AddressFormControls } from "@/config";
import CommonForm from "../common/form";
import { Card, CardContent, CardHeader, CardTitle } from "../ui/card";
import { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { addNewAddress, fetchAllAddress } from "@/store/shop/address-slice";
import AddressCard from "./addressCard";
const initialFormData = {
  address: "",
  city: "",
  pincode: "",
  phone: "",
  notes: ""
};
export default function Address() {
  const dispatch = useDispatch();
  const [formData, setFormData] = useState(initialFormData);
  const { user } = useSelector((state) => state.auth);
  const { addressList } = useSelector((state) => state.shopAddress);


  function handleManageAddress(event) {
    event.preventDefault();
    dispatch(addNewAddress({ userId: user.id, ...formData })).then((data) => {
      console.log(data);
      if(data?.payload?.success){
        dispatch(fetchAllAddress({ userId: user?.id }))
        setFormData(initialFormData);
      }
    });
  }

  
function isFormDataValid() {
  const ans = Object.entries(formData).every(([key, val]) => {
    if (typeof val === "string") {
      return val.trim() !== "";
    }
    if (typeof val === "number") {
      return !isNaN(val) && val.toString().trim() !== "";
    }
    return false;
  });
  console.log("isFormDataValid", ans);
  return ans;
}
useEffect(()=>{
    dispatch(fetchAllAddress( user?.id ));
},[dispatch])

console.log("addressList", addressList);    
  return (
    <Card>
      <div className="mb-5 p-3 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2">
        {
            addressList && addressList.length > 0 ? addressList.map((address)=>(
               <AddressCard addressInfo={address} key={address.id}/>
            )): <p>No address found</p>
        }
      </div>
      <CardHeader>
        <CardTitle>Add new Address</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <CommonForm
          formControls={AddressFormControls}
          formData={formData}
          setFormData={setFormData}
          buttonText="Add"
          onSubmit={handleManageAddress}
          isBtnDisabled={!isFormDataValid()}
        />
      </CardContent>
    </Card>
  );
}
