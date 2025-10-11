import { Button } from "../ui/button";
import { Card, CardContent, CardFooter } from "../ui/card";
import { Label } from "../ui/label";

export default function AddressCard({addressInfo,handleDelete,handleEditAddress,setCurrentAddress}) {
     
    return (
        <Card onClick={ () => setCurrentAddress(addressInfo)} className="cursor-pointer hover:shadow-lg transition-shadow duration-300">
            <CardContent className='grid p-4 gap-4'>
                <Label>Address : {addressInfo?.address}</Label>
                <Label>City : {addressInfo?.city}</Label>
                <Label>Pincode : {addressInfo?.pincode}</Label>
                <Label>Phone : {addressInfo?.phone}</Label>
                <Label>Notes : {addressInfo?.notes}</Label>   
            </CardContent>
            <CardFooter className='flex justify-between gap-2'>
                <Button className="m-2" onClick={() => handleEditAddress(addressInfo)}>Edit</Button>
                <Button variant="destructive" onClick={() => handleDelete(addressInfo)}>Delete</Button>
            </CardFooter>
        </Card>
    )
}