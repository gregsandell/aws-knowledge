# lambda-sends-email
> You do NOT need to supply any SMTP provider unless you want to.
> <br/>AWS gives you its own built-in email-sending service, AWS SES.

AWS gives you its own built-in email-sending service:
Copied from ChatGPT:

Nice — sending an email from a Lambda is common. The easiest and most AWS-native way is **Amazon SES (Simple Email Service)**. Below I’ll give you:

1. A concise checklist of required setup steps (SES verification, sandbox note).

2. A ready-to-drop Node.js Lambda handler (AWS SDK v3) that sends an email.

3. The IAM permissions the Lambda needs.

4. A SAM / CloudFormation snippet showing how to attach the policy and env vars to the Lambda.

5. Alternatives and tips (SNS, 3rd-party SMTP, error handling, testing).

## 1) Quick checklist (what you must do first)

* Enable SES in the region you plan to use (SES is region-specific).

* **Verify the sender email address** (or verify your domain) in SES:

  * If SES is still in **sandbox**, you must also verify the recipient address. Sandbox restricts sending.

  * To remove sandbox restrictions, request production access in the SES console.

* Create or update the Lambda execution role with SES send permissions (`ses:SendEmail, ses:SendRawEmail`).

* Configure the Lambda with environment variables for the `FROM` and `TO` addresses (or pass recipients in the event).

## 2) Node.js example (Lambda handler) — AWS SDK v3

See the `index.js` file. This expects `TABLE_NAME`? ignore. We'll use `SES_FROM` and `SES_TO` env vars (recommended). Node 18+ runtime.


### package.json (minimal)
```json

{
"name": "lambda-ses-send",
"version": "1.0.0",
"dependencies": {
"@aws-sdk/client-ses": "^3.400.0"
}
}
```


## 3) IAM permissions (minimum)

Attach to the Lambda execution role:
```json

{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Action": [
"ses:SendEmail",
"ses:SendRawEmail"
],
"Resource": "*"
},
{
"Effect": "Allow",
"Action": [
"logs:CreateLogGroup",
"logs:CreateLogStream",
"logs:PutLogEvents"
],
"Resource": "*"
}
]
}
```


* For tightest security, replace `"Resource": "*"` with the SES identity ARNs (if you know them), or limit to `arn:aws:ses:<region>:<account-id>:identity/yourdomain.com` and mailbox identities. But SES APIs often allow `"*"` for send actions depending on use — keep in mind principle of least privilege.

## 4) SAM template snippet — wiring env vars and policy

Add/replace your function resource in SAM template with:
```yaml

Resources:
    FooLambda:
    Type: AWS::Serverless::Function
    Properties:
        FunctionName: foo-lambda
        Handler: index.handler
        Runtime: nodejs18.x
        CodeUri: .
        Environment:
            Variables:
                SES_FROM: "no-reply@yourdomain.com"
                SES_TO: "recipient@example.com"
        Policies:
            - Version: "2012-10-17"
            Statement:
                - Effect: Allow
                Action:
                    - ses:SendEmail
                    - ses:SendRawEmail
                Resource: "*"
```


Notes:

* `CodeUri: .` assumes you package code and deps; with `InlineCode` you could include code inline but with external dependency `@aws-sdk/client-ses` it's better to package.

* SAM `Policies` convenience can accept inline policy objects like shown or reference an IAM role.

## 5) SES verification & CLI commands (quick reference)

* Verify sender email (CLI):
```bash
aws ses verify-email-identity --region us-east-1 --email-address no-reply@yourdomain.com
```

* Verify domain (recommended for production — DNS records required):
```bash
aws ses verify-domain-identity --region us-east-1 --domain yourdomain.com
```

* Check verification status:
```bash
aws ses get-identity-verification-attributes --identities no-reply@yourdomain.com
````

* If in sandbox: verify recipient email the same way (or request production access in SES console).

## 6) Alternatives & notes

* **Amazon SNS:** You can publish to an SNS topic and subscribe an email endpoint. This requires the recipient to confirm the subscription (not practical for one-off notifications to arbitrary addresses). Good for internal, subscribed users.

* **Third-party SMTP (SendGrid, Mailgun, etc.)**: Use nodemailer or the provider SDK. This avoids SES verification but introduces external API keys and possible costs.

* **SES templates / HTML:** For nicer formatting and localization, consider SES templates (SendTemplatedEmail).

**Retries & errors:** If Lambda fails while sending email, Lambda will behave according to its invocation type:

  * For synchronous invocations (API Gateway), the caller receives the error.

  * For asynchronous / event invocation, Lambda may retry. Consider idempotency (don’t send duplicates) or log send status separately.

* **Cost:** SES has low per-email costs; check AWS pricing for your region.

##  7) Testing tips

* Start by verifying both sender and recipient if SES is in sandbox.

* Deploy the Lambda and invoke it from the console with a small test event; check CloudWatch logs for any SES errors.

* If you see `MessageRejected` errors, check that sender/recipient are verified or that you are out of sandbox.

* For browser-triggered emails, ensure you don’t expose secrets in the client. Always call Lambda from the server side.

