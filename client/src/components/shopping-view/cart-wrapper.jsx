import { SheetContent, SheetHeader, SheetTitle } from "../ui/sheet";


function UserCartWrapper(){
    return <SheetContent className='sm:max-w-md'>
        <SheetHeader>
            <SheetTitle>Your chart</SheetTitle>
        </SheetHeader>
    </SheetContent>
}

export default UserCartWrapper;