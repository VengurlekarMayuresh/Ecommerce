import CommonForm from "@/components/common/form";
import { Button } from "@/components/ui/button";
import { SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Sheet } from "@/components/ui/sheet";
import React, { Fragment, useEffect, useState } from "react";
import { addProductFormControls } from "@/config";
import ProductImageUpload from "@/components/admin-view/image-uplaod";
import { useDispatch, useSelector } from "react-redux";
import { addNewProduct, fetchProducts } from "@/store/admin/products-slice";
import { toast } from "sonner";
import AdminProductTile from "@/components/admin-view/product-tile";

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
  const [currentEditedId, setCurrentEditedId] = useState(null);
  const { products } = useSelector((state) => state.adminProducts);
  const dispatch = useDispatch();

  function onSubmit(event) {
    event.preventDefault();
    dispatch(addNewProduct({ ...formdata, image: uploadedImageUrl })).then(
      (data) => {
        if (data.payload.success) {
          dispatch(fetchProducts());
          setImageFile(null);
          setFormData(initialFormData);
          setOpenCreateProduct(false);

          toast.success("Product added successfully");
        }
      }
    );
  }
  console.log(products);
  useEffect(() => {
    dispatch(fetchProducts());
  }, [dispatch]);
  return (
    <Fragment>
      <div className="mb-5 w-full flex justify-end">
        <Button onClick={() => setOpenCreateProduct(true)}>
          Add New Products
        </Button>
      </div>
      <div className="grid gap-4 md:grid-cols-3 lg:grid-cols-4">
        {products && products.length > 0 ? 
          products.map((product) => (
            <AdminProductTile key={product._id} product={product} />
          )): " No Products Found"}
      </div>
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
