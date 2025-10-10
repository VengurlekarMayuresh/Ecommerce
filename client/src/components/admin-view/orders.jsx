import { useState } from "react";
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
import AdminOrdersDetailsView from "./order-details";

function AdminOrdersView() {
    const [openDetailsDialog, setOpenDetailsDialog] = useState(false);
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
            <TableRow>
              <TableCell className="text-left">123654</TableCell>
              <TableCell className=" text-left">2023-10-01</TableCell>
              <TableCell className=" text-left">Shipped</TableCell>
              <TableCell className=" text-left">$99.99</TableCell>
              <TableCell className=" text-center">
                <Dialog open={openDetailsDialog} onOpenChange={setOpenDetailsDialog}>
                  <Button variant="outline" size="sm" onClick={() => setOpenDetailsDialog(true)}>View Details</Button>
                <AdminOrdersDetailsView/>
                </Dialog>
           
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}

export default AdminOrdersView;
