const User = require("../models/user");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const registerUser = async (req, res) => {
  const { userName, email, password } = req.body;
  try {
    const checkUser = await User.findOne({ email });
    if (checkUser) {
      console.log("User Already Exists");
      return res.json({ message: "User Already Exists", success: false });
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new User({
      userName,
      email,
      password: hashedPassword,
    });
    await newUser
      .save()
      .then(() => {
        console.log("User Registered Successfully");
      })
      .catch((err) => {
        console.log(err);
      });
    res
      .status(201)
      .json({ message: "User Registered Successfully", success: true });
  } catch (error) {
    console.log("Error During registration" + error);
    res.status(500).json({ error: "Internal Server Error", success: false });
  }
};

const loginUser = async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) {
      res.json({ message: "User Not Found", success: false });
    }
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.json({ message: "Invalid credentials", success: false });
    }
    const payLoad = {
      email: user.email,
      id: user._id,
      role: user.role,
      userName: user.userName,
    };
    const token = jwt.sign(payLoad, process.env.SECRET_KEY, {
      expiresIn: 3600,
    });
    return res.cookie("token", token, { httpOnly: true, secure: false }).json({
      success: true,
      message: "Login Successfully",
      user: {
        id: user._id,
        userName: user.userName,
        email: user.email,
        role: user.role,
        username: user.userName,
      },
    });
  } catch (error) {
    console.log("Error During Login" + error);
    res.status(500).json({ error: "Internal Server Error", success: false });
  }
};

const logoutUser = (req, res) => {
  return res.clearCookie("token").json({
    success: true,
    message: "Logout Successfully",
  });
};

//authMiddleware
const authMiddleware = async (req, res, next) => {
  const token = req.cookies.token;
  if (!token)
    return res.status(401).json({
      success: false,
      message: "Unauthorized User",
    });
  try {
    const decoded = jwt.verify(token, process.env.SECRET_KEY);
    req.user = decoded;
   return next();
  } catch (error) {
    console.log(error);
    return res.status(401).json({
      success: false,
      message: "Unauthorized User ",
    } )
  }
};
module.exports = { registerUser, loginUser, logoutUser, authMiddleware };
