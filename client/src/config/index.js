import { Label } from "@radix-ui/react-label";

export const registerFormControls = [
    {
        name:'userName',
        label: 'User Name',
        placeholder : 'Enter your User Name',
        componentType: 'input',
        type:'text'
    },
        {
        name:'email',
        label: 'Email',
        placeholder : 'Enter your Email',
        componentType: 'input',
        type:'email'
    },
        {
        name:'password',
        label: 'password',
        placeholder : 'Enter your Password',
        componentType: 'input',
        type:'password'
    }
]

export const loginFormControls = [
        {
        name:'email',
        label: 'Email',
        placeholder : 'Enter your Email',
        componentType: 'input',
        type:'email'
    },
        {
        name:'password',
        label: 'password',
        placeholder : 'Enter your Password',
        componentType: 'input',
        type:'password'
    }
]

export const addProductFormControls = [
    {
        label:'Title',
        name:'title',
        componentType:'input',
        type:'text',
        placeholder:'Enter Product Title'
    },
    {
        label:'Description',
        name:'description',
        componentType:'textarea',
        type:'text',
        placeholder:'Enter Product Description'
    },
    {
        label:'Price',
        name:'price',
        componentType:'input',
        type:'number',
        placeholder:'Enter Product Price'
    },
    {
        label:'Category',
        name:'category',
        componentType:'select',
        options :[
            {id:'men',label:'Men'},
            {id:'women',label:'Women'},
            {id:'kids',label:'Kids'},
            {id:'accessories',label:'Accessories'},
            {id:'electronics',label:'Electronics'},
            {id:'home',label:'Home'},

        ]
    },
    {
        label:'brand',
        name:'brand',
        componentType:'select',
        options :[
            {id:'nike',label:'Nike'},
            {id:'adidas',label:'Adidas'},
            {id:'puma',label:'Puma'},
            {id:'levi',label:'Levi'},
            {id:'zara',label:'Zara'},
            {id:'h&m',label:'H&M'},
        ]
    },{
        label:'Sales Price',
        name:'salesPrice',
        type:'number',
        componentType:'input',
        placeholder:'Enter Sales Price'
    },
    {
        label:'Total Stock',
        name:'totalStock',
        type:'number',
        componentType:'input',
        placeholder:'Enter Total Stock'
    }
]