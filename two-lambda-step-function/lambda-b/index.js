exports.handler = async (event) => {
    console.log("LambdaB received:", JSON.stringify(event));

    const n = event.numberFromA;

    return {
        message: "LambdaB received a number",
        originalNumber: n,
        doubled: n * 2
    };
};
