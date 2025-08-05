exports.handler = async (event) => {
    console.log("Event: ", event);

   
    const response = {
        statusCode: 200,
        body: JSON.stringify({ message: "User authenticated successfully!" }),
    };
    
    return response;
};
