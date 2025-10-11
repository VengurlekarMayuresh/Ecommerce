import { useEffect, useState } from "react";
import { Button } from "../ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../ui/card";
import { Dialog } from "../ui/dialog";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "../ui/table";
import ShoppingOrderDetailsView from "./order-details";
import { useDispatch, useSelector } from "react-redux";
import { getAllOrders } from "@/store/shop/order-slice";
import { Badge } from "../ui/badge";

export default function ShoppingOrders() {
  const [openDetailsDialog, setOpenDetailsDialog] = useState(false);
  const dispatch = useDispatch();
  const { user } = useSelector((state) => state.auth);
  const { orderList } = useSelector((state) => state.shoppingOrder);

  useEffect(() => {
    dispatch(getAllOrders(user?.id));
  }, [dispatch]);

  return (
    <Card>
      <CardHeader>
        <CardTitle>Order History</CardTitle>
      </CardHeader>

      <CardContent>
        <Table className="w-full border-collapse">
          <TableHeader>
            <TableRow>
              <TableHead className="align-middle text-left">Order ID</TableHead>
              <TableHead className="align-middle text-left">
                Order Date
              </TableHead>
              <TableHead className="align-middle text-left">
                Order Status
              </TableHead>
              <TableHead className="align-middle text-left">
                Order Price
              </TableHead>
              <TableHead className="align-middle text-center">
                <span className="sr-only">Action</span>
              </TableHead>
            </TableRow>
          </TableHeader>

          <TableBody>
            {
              orderList && orderList.length > 0 ? orderList.map((orderItem) => (
                 <TableRow key={orderItem._id}>
              <TableCell className="text-left">{orderItem._id}</TableCell>
              <TableCell className=" text-left">{orderItem.orderDate.split('T')[0]}</TableCell>
              <TableCell className=" text-left"><Badge className={orderItem.orderStatus == 'confirmed' ? 'bg-green-500' : 'bg-red-500 , py-1 px-3'}>{orderItem.orderStatus}</Badge></TableCell>
              <TableCell className=" text-left">${orderItem.totalAmount}</TableCell>
              <TableCell className=" text-center">
                <Dialog
                  open={openDetailsDialog}
                  onOpenChange={setOpenDetailsDialog}
                >
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setOpenDetailsDialog(true)}
                  >
                    View Details
                  </Button>
                  <ShoppingOrderDetailsView />
                </Dialog>
              </TableCell>
            </TableRow>
              )) : <TableRow>
              <TableCell colSpan={5} className="text-center">
                No orders found.
              </TableCell>
            </TableRow>
            }
           
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}
