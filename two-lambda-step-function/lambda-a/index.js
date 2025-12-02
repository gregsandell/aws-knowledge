exports.handler = async (event) => {
    console.log("LambdaA received:", JSON.stringify(event));

    const numberToPass = 42; // or any computed number

    return {
        number: numberToPass,
        note: "This number will be passed to LambdaB"
    };
};
