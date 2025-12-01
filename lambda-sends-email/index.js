// index.js
const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");

const REGION = process.env.AWS_REGION || "us-east-1";
const ses = new SESClient({ region: REGION });

const FROM = process.env.SES_FROM; // e.g. "no-reply@yourdomain.com"
const TO = process.env.SES_TO;     // comma separated or single "recipient@example.com"

if (!FROM) {
    console.warn("SES_FROM not set in environment variables");
}

exports.handler = async (event) => {
    // Build a simple message
    const now = new Date().toISOString();
    const subject = `Lambda foo-lambda executed at ${now}`;
    const textBody = `Hello,\n\nYour Lambda foo-lambda ran at ${now}.\n\nEvent summary:\n${JSON.stringify(event, null, 2)}\n`;
    const htmlBody = `<html><body><p>Hello,</p><p>Your Lambda <b>foo-lambda</b> ran at ${now}.</p><pre>${escapeHtml(JSON.stringify(event, null, 2))}</pre></body></html>`;

    const toAddresses = (process.env.SES_TO || "").split(",").map(s => s.trim()).filter(Boolean);

    if (!toAddresses.length) {
        console.error("No recipient set in SES_TO. Aborting send.");
        return { statusCode: 500, body: "No SES_TO configured" };
    }

    const params = {
        Destination: {
            ToAddresses: toAddresses
        },
        Message: {
            Body: {
                Html: { Data: htmlBody },
                Text: { Data: textBody }
            },
            Subject: { Data: subject }
        },
        Source: FROM
        // If you have multiple verified identities and want to specify configuration set:
        // ConfigurationSetName: process.env.SES_CONFIGURATION_SET
    };

    try {
        const cmd = new SendEmailCommand(params);
        const resp = await ses.send(cmd);
        console.log("SES send result:", resp);
        return { statusCode: 200, body: JSON.stringify({ message: "Email sent", result: resp }) };
    } catch (err) {
        console.error("Failed to send email via SES:", err);
        // handle or rethrow depending on your retry strategy
        return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
    }
};

// small helper to escape HTML in event dump
function escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}
