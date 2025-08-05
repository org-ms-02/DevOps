const express = require('express');
const app = express();

app.get('/products', (req, res) => {
    res.json({ products: ["Product 1", "Product 2", "Product 3"] });
});

app.listen(8080, () => {
    console.log("Product catalog API is running on port 8080");
});
