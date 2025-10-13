import { useEffect, useState } from "react";
import { Button } from "../ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../ui/card";
import { Dialog } from "../ui/dialog";
import { Badge } from "../ui/badge";

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "../ui/table";
import AdminOrdersDetailsView from "./order-details";
import { useDispatch, useSelector } from "react-redux";
import {
  getAllOrdersForAdmin,
  getOrderDetailsForAdmin,
  resetOrderDetails,
} from "@/store/admin/order-slice";

function AdminOrdersView() {
  const [openDetailsDialog, setOpenDetailsDialog] = useState(false);
  const { orderDetails, orderList } = useSelector((state) => state.adminOrder);
  const dispatch = useDispatch();

  function handleFetchOrderDetails(orderId) {
    dispatch(getOrderDetailsForAdmin(orderId));
  }

  useEffect(() => {
    if (orderDetails) {
      setOpenDetailsDialog(true);
    }
  }, [orderDetails]);

  useEffect(() => {
    dispatch(getAllOrdersForAdmin());
  }, [dispatch]);

  return (
    <Card>
      <CardHeader>
        <CardTitle>All Orders </CardTitle>
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
            {orderList && orderList.length > 0 ? (
              orderList.map((orderItem) => (
                <TableRow key={orderItem._id}>
                  <TableCell className="text-left">{orderItem._id}</TableCell>
                  <TableCell className=" text-left">
                    {orderItem.orderDate.split("T")[0]}
                  </TableCell>
                  <TableCell className=" text-left">
                    <Badge
                      className={`py-1 px-3 ${
                        orderDetails?.orderStatus == "confirmed"
                          ? "bg-green-500"
                          : orderDetails?.orderStatus == "rejected"
                          ? "bg-red-500"
                          : "bg-black"
                      }`}
                    >
                      {orderItem.orderStatus}
                    </Badge>
                  </TableCell>
                  <TableCell className=" text-left">
                    ${orderItem.totalAmount}
                  </TableCell>
                  <TableCell className=" text-center">
                    <Dialog
                      open={openDetailsDialog}
                      onOpenChange={() => {
                        setOpenDetailsDialog(false);
                        dispatch(resetOrderDetails());
                      }}
                    >
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleFetchOrderDetails(orderItem._id)}
                      >
                        View Details
                      </Button>
                      <AdminOrdersDetailsView orderDetails={orderDetails} />
                    </Dialog>
                  </TableCell>
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={5} className="text-center">
                  No orders found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}

export default AdminOrdersView;
