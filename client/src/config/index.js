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