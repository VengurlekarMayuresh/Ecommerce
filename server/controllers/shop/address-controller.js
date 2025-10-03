const Address = require("../../models/Address");
const addAddress = async (req, res) => {
  try {
    const { userId, address, city, pincode, phone, notes } = req.body;
    if (!userId || !address || !city || !pincode || !phone || !notes) {
      return res
        .status(400)
        .json({ message: "All fields are required", success: false });
    }
    const newAddress = new Address({
      userId,
      address,
      city,
      pincode,
      phone,
      notes,
    });
    await newAddress.save();
    res
      .status(201)
      .json({
        message: "Address added successfully",
        success: true,
        data: newAddress,
      });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Internal Server Error", success: false });
  }
};

const editAddress = async (req, res) => {
  try {
    const { userId, addressId } = req.params;
    const formData = req.body;
    if(!userId || !addressId){
      return res.status(400).json({message:"UserId and AddressId are required", success:false});
    }
    const address = await Address.findOneAndUpdate({_id:addressId, userId}, formData, {new:true});
    if(!address){
      return res.status(404).json({message:"Address not found", success:false});
    }
    res.status(200).json({message:"Address updated successfully", success:true, data:address});
  
} catch (error) {
    console.log(error);
    res.status(500).json({ message: "Internal Server Error", success: false });
  }
};

const deleteAddress = async (req, res) => {
  try {
    const { userId, addressId } = req.params;
    if(!userId || !addressId){
      return res.status(400).json({message:"UserId and AddressId are required", success:false});
    }
    const address = await Address.findOneAndDelete({_id:addressId, userId});
    if(!address){
      return res.status(404).json({message:"Address not found", success:false});
    }
    res.status(200).json({message:"Address deleted successfully", success:true});
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Internal Server Error", success: false });
  }
};

const fetchAllAddress = async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) {
      return res
        .status(400)
        .json({ message: "UserId is required", success: false });
    }
    const addressList = await Address.find({ userId });
    res
      .status(200)
      .json({
        message: "Addresses fetched successfully",
        success: true,
        data: addressList,
      });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Internal Server Error", success: false });
  }
};

module.exports = {
  addAddress,
  editAddress,
  deleteAddress,
  fetchAllAddress,
};
