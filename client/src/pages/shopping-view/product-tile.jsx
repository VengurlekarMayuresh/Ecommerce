import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardFooter } from "@/components/ui/card";
import { brandOptions, categoryOptions } from "@/config";
import React from "react";

export default function ShoppingProductTile({ product , handleGetProductDetails }) {
  return (
    <Card className="w-full max-w-sm mx-auto px-4">
      <div onClick={() => handleGetProductDetails(product._id)}>
        <div className="relative">
          <img
            src={product.image}
            alt={product.title}
            className="w-full h-[280px] object-cover rounded-t-lg"
          />
          {product?.salesPrice > 0 ? (
            <Badge className="absolute top-2 left-2 bg-red-500 hover:bg-red-600">
              Sales
            </Badge>
          ) : null}
        </div>
        <CardContent className="p-4">
          <h2 className="text-xl font-bold mb-2">{product.title}</h2>
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm text-muted-foreground">
              {product.category}
            </span>
            <span className="text-sm text-muted-foreground">
              {product.brand}
            </span>
          </div>
          <div className="flex items-center justify-between mb-2">
            <span
              className={`${
                product?.salesPrice > 0 ? "line-through" : ""
              } text-lg font-semibold text-primary`}
            >
              ${product?.price}
            </span>
            {product?.salesPrice > 0 ? (
              <span className="text-lg font-semibold text-primary">
                ${product?.salesPrice}
              </span>
            ) : null}
          </div>
        </CardContent>
        <CardFooter>
          <Button className="w-full">Add to Cart </Button>
        </CardFooter>
      </div>
    </Card>
  );
}
