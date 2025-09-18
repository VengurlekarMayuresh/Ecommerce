const Product = require("../../models/product");
const getFilteredProducts = async (req, res) => {
  try {
    const {category = [], brand = [],sortBy ='price-low-to-high' } = req.query;
    let filters = {};
    if (category.length) {
      filters.category = { $in: category.split(",") };
    }
    if (brand.length) {
      filters.brand = { $in: brand.split(",") };
    }
    let sort = [];
    switch(sortBy) {
      case 'price-low-to-high': sort.price = 1 ; break;
      case 'price-high-to-low': sort.price = -1 ; break;
      case 'newest-first': sort.createdAt = -1 ; break;
      case 'oldest-first': sort.createdAt = 1 ; break;
      case 'title-a-to-z': sort.title = 1 ; break;
      case 'title-z-to-a': sort.title = -1 ; break;
      default: sort.price = 1 ;
    }
    const products = await Product.find({});
    res.status(200).json({ success: true, data: products });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server Error", error: error.message });
  }
};

module.exports = { getFilteredProducts };
