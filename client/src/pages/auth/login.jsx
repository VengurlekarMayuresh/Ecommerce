import CommonForm from "@/components/common/form";
import React, { useState } from "react";
import { Link } from "react-router-dom";
import { loginFormControls } from "@/config";
import { useDispatch } from "react-redux";
import { loginUser } from "@/store/auth-slice";
import { toast } from "sonner"
import { useNavigate } from "react-router-dom";




export default function AuthLogin() {
 const  initialState = {
    email: "",
    password: "",
  };
  const dispatch  = useDispatch();
const navigate = useNavigate();
  function onSubmit(event) {
    event.preventDefault();
    dispatch(loginUser(formData)).then((data) => {
      if(data.payload?.success){
        toast.success(data?.payload?.message);
        navigate("/shop/home");
      }else{
        toast.error(data?.payload?.message);
      }
    });
  }
  const [formData, setFormData] = useState(initialState);
  return (
    <div className="mx-auto w-full max-w-md space-y-6">
      <div className="text-center">
        <h1 className="text-3xl font-bold tracking-tight text-foreground ">
          Sign in to your Account
        </h1>
        <p>Don't have an account</p>
        <Link
          className="font-medium  text-primary hover:underline"
          to="/auth/register"
        >
          Register
        </Link>
      </div>
      <CommonForm
        formControls={loginFormControls}
        formData={formData}
        setFormData={setFormData}
        buttonText="Sign Up"
        onSubmit={onSubmit}
      />
    </div>
  );
}
