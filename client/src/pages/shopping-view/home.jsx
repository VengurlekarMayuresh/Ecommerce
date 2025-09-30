import React, { useEffect, useState } from "react";
import bannerone from "../../assets/banner-1.jpg";
import bannertwo from "../../assets/banner-2.jpg";
import { Button } from "@/components/ui/button";
import { BabyIcon, ChevronLeftIcon, ChevronRightIcon, CloudLightning, ShirtIcon, UmbrellaIcon, WatchIcon } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { useDispatch, useSelector } from "react-redux";
import { fetchAllFilteredProducts } from "@/store/shop/products-slice";
const categories = [
      { id: "men", label: "Men", icon: ShirtIcon },
      { id: "women", label: "Women", icon: CloudLightning },
      { id: "kids", label: "Kids", icon: BabyIcon },
      { id: "accessories", label: "Accessories", icon: WatchIcon },
      { id: "electronics", label: "Electronics", icon: UmbrellaIcon },
    ]

export default function ShoppingHome() {
  const slides = [bannerone, bannertwo];
  const dispatch = useDispatch();
  const shopProducts = useSelector((state) => state.shoppingProducts.products);
  console.log("Shop Products:", shopProducts);
const [currentSlide, setCurrentSlide] = useState(0);
useEffect(()=>{
  const timer = setInterval(() => {
    setCurrentSlide((prev) => (prev === slides.length - 1 ? 0 : prev + 1));
  }, 4000);
  return () => clearInterval(timer);
},[])

useEffect(()=>{
  dispatch(fetchAllFilteredProducts({filterParams:{},sortParams:'price-low-to-high'}))
},[dispatch])

  return (
    <div className="flex flex-col min-h-screen">
      <div className="relative w-full h-[600px] overflow-hidden">
        {slides.map((slide, index) => (
          <img
            src={slide}
            key={index}
            className={`absolute top-0 left-0 w-full h-full object-cover transition-opacity duration-1000 ease-in-out ${currentSlide === index ? "opacity-100" : "opacity-0"
              }`}
          />
        ))}
        <Button
          variant="outline"
          size="icon"
          className="absolute top-1/2 left-4 -translate-y-1/2 bg-white/70 hover:bg-white"
          onClick={() => setCurrentSlide((prev) => (prev === 0 ? slides.length - 1 : prev - 1))}
        >
          <ChevronLeftIcon className="w-5 h-5" />
        </Button>
          <Button
          variant="outline"
          size="icon"
          className="absolute top-1/2 right-4 -translate-y-1/2 bg-white/70 hover:bg-white"
          onClick={() => setCurrentSlide((prev) => (prev === slides.length - 1 ? 0 : prev + 1))}
        >
          <ChevronRightIcon className="w-5 h-5" />
        </Button>
      </div>
      <section className="py-12 bg-gray-50">
        <div className="container mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-8">Shop By Category</h2>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
            {
              categories.map((category) => (
                <Card className='cursor-pointer hover:shadow-lg transition-shadow'>
                  <CardContent className='flex flex-col items-center justify-center p-6'>
                    <category.icon className="w-12 h-12 mb-2 text-primary"/>
                <span className="text-xl font-bold">{category.label}</span>
                  </CardContent>
                </Card>
              ))
            }
            </div>            
        </div>
      </section>
    </div>
  );
}
