exports.handler = async (event) => {
    console.log("Payment event: ", event);

    // Simulate payment processing
    const response = {
        statusCode: 200,
        body: JSON.stringify({ message: "Payment processed successfully!" }),
    };

    return response;
};

