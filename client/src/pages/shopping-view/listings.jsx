import ProductFilter from "@/components/shopping-view/filter";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { sortOptions } from "@/config";
import { fetchProducts } from "@/store/admin/products-slice";
import { fetchAllFilteredProducts } from "@/store/shop/products-slice";
import { ArrowUpDown, ArrowUpDownIcon } from "lucide-react";
import React, { useEffect, useState } from "react";
import { useDispatch } from "react-redux";
import { useSelector } from "react-redux";
import ShoppingProductTile from "./product-tile";
import { createSearchParams, useSearchParams } from "react-router-dom";

export default function ShoppingListings() {
  const dispatch = useDispatch();
  const [filters, setFilters] = useState({});
  const [sort, setSort] = useState(null);
  const { products, isLoading } = useSelector((state) => state.shoppingProducts);
  const [searchParams, setSearchParams] = useSearchParams();

function handleSortChange(value) {
  console.log("Selected sort:", value);
  setSort(value);
}

function createSearchParams(filters) {
  const query = [];
  for(const [key,value] of Object.entries(filters)){
    if(Array.isArray(value) && value.length > 0){
      const paramValue = value.join(',');
      query.push(`${key}=${encodeURIComponent(paramValue)}`);
    }
  return query.join('&');
}}

function handleFilter(getSectionId,getCurrentOption){
  console.log("Selected filter:", getSectionId,getCurrentOption);
  let cpyFilters = {...filters};
  const indexOfCurrentSection = Object.keys(cpyFilters).indexOf(getSectionId);
  if(indexOfCurrentSection ===-1){
    cpyFilters = {...cpyFilters,[getSectionId]:[getCurrentOption]}
  }else{
    const indexOfCurrentOption = cpyFilters[getSectionId].indexOf(getCurrentOption);
    if(indexOfCurrentOption === -1){
      cpyFilters[getSectionId].push(getCurrentOption);
    }else{
      cpyFilters[getSectionId].splice(indexOfCurrentOption,1);
      // if(cpyFilters[getSectionId].length === 0){
      //   delete cpyFilters[getSectionId];
      // }
    }
}
  setFilters(cpyFilters);
  sessionStorage.setItem("productFilters",JSON.stringify(cpyFilters));
}

useEffect(()=>{
  setSort('price-low-to-high')
  setFilters(JSON.parse(sessionStorage.getItem("productFilters")) || {});
},[])

useEffect(()=>{
  if(filters && Object.keys(filters).length > 0){
    let queryParams = createSearchParams(filters);
    setSearchParams(new URLSearchParams(queryParams));
  }
},[filters])

  useEffect(() => {
    dispatch(fetchAllFilteredProducts());
  }, [dispatch]);
 

  return (
    <div className="grid grid-cols-1 md:grid-cols-[200px_1fr] gap-6 p-4 md:p-6">
      <ProductFilter filters={filters} handleFilter={handleFilter} />
      <div className="bg-background w-full rounded-lg shadow-sm">
        <div className="p-4 border-b flex items-center justify-between">
          <h2 className="text-lg font-extrabold">All Products</h2>
          <div className="flex items-center gap-3">
            <span className="text-muted-foreground">
              {products?.length} Products
            </span>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button
                  variant="outline"
                  size="sm"
                  className="flex items-center gap-1"
                >
                  <ArrowUpDownIcon className="h-4 w-4" />
                  <span>Sort By</span>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-[200px]">
                <DropdownMenuRadioGroup value={sort} onValueChange={handleSortChange}>
                  {sortOptions.map((sortItem) => (
                    <DropdownMenuRadioItem key={sortItem.id} value={sortItem.id}>
                      {sortItem.label}
                    </DropdownMenuRadioItem>
                  ))}
                </DropdownMenuRadioGroup>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 p-4">
          {products && products.length > 0
            ? products.map((product) => (
                <ShoppingProductTile key={product._id} product={product} />
              ))
            : null}
        </div>
      </div>
    </div>
  );
}
