import CommonForm from "@/components/common/form";
import { Button } from "@/components/ui/button";
import { SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Sheet } from "@/components/ui/sheet";
import React, { Fragment, useState } from "react";
import { addProductFormControls } from "@/config";
import ProductImageUpload from "@/components/admin-view/image-uplaod";
import { useDispatch, useSelector } from "react-redux";
import { addNewProduct } from "@/store/admin/products-slice";

const initialFormData = {
  image: null,
  title: "",
  description: "",
  price: "",
  category: "",
  brand: "",
  salesPrice: "",
  totalStock: "",
};

export default function AdminProducts() {
  const [openCreateProduct, setOpenCreateProduct] = useState(false);
  const [formdata, setFormData] = useState(initialFormData);
  const [imageFile, setImageFile] = useState(null);
  const [uploadedImageUrl, setUploadedimageUrl] = useState("");
  const [imageLoading, setImageLoading] = useState(false);
  const { products } = useSelector((state) => state.adminProducts);
  const dispatch = useDispatch();

  
  function onSubmit(event) {
    event.preventDefault();
    dispatch(
      addNewProduct({ ...formdata, image: uploadedImageUrl })
    ).then((data)=>{
      console.log(data);
    })
  }

  return (
    <Fragment>
      <div className="mb-5 w-full flex justify-end">
        <Button onClick={() => setOpenCreateProduct(true)}>
          Add New Products
        </Button>
      </div>
      <div className="grid gap-4 md:grid-cols-3 lg:grid-cols-4"></div>
      <Sheet
        open={openCreateProduct}
        onOpenChange={() => setOpenCreateProduct(false)}
      >
        <SheetContent side="right" className="overflow-auto">
          <SheetHeader className="pb-0">
            <SheetTitle>Add New Product</SheetTitle>
          </SheetHeader>
          <ProductImageUpload
            file={imageFile}
            setFile={setImageFile}
            uploadedImageUrl={uploadedImageUrl}
            setUploadedImageUrl={setUploadedimageUrl}
            setImageLoading={setImageLoading}
            imageLoading={imageLoading}
          />
          <div className="py-5 px-5">
            <CommonForm
              formControls={addProductFormControls}
              formData={formdata}
              setFormData={setFormData}
              buttonText="Add Product"
              onSubmit={onSubmit}
            />
          </div>
        </SheetContent>
      </Sheet>
    </Fragment>
  );
}
