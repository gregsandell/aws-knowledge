# option2-with-permissions
> Note: I have not tried this yet.  These come from instructions given to me by Chat-gpt.

## Purpose
Considered a _Explicit: CloudFormation (HTTP API v2) + Lambda_ appraoch, in case you want explicit CloudFormation resources of role, integration and permission, rather than having them abstracted away by the Serverless Application Model (SAM) as in option1-aws-sam.
## Steps
Run:
```bash
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name hello-cfn-stack \
  --capabilities CAPABILITY_NAMED_IAM
```

Get the endpoint URL:
```bash
aws cloudformation describe-stacks --stack-name hello-cfn-stack --query "Stacks[0].Outputs"
```

## Other instructions and tips
1. Permissions: The Lambda needs AWSLambdaBasicExecutionRole (CloudWatch logs) at minimum. SAM sets that up automatically for you.
2. CORS: If you’ll call from browser fetch() from a different origin, you must enable CORS on the API or return appropriate Access-Control-Allow-Origin headers. For a quick test you can return headers: { "Access-Control-Allow-Origin": "*" } in the Lambda response.
3. HTTP API vs REST API:
    * HTTP API (ApiGatewayV2) is simpler, cheaper, and fine for most use-cases.
    * REST API (ApiGateway) has more features (API keys, usage plans, request/response mapping templates) but is more complex and costlier.
4. Local testing: sam local start-api lets you run and call the API locally (requires Docker).
5. Environment variables: Configure them on the Lambda (in the template) — API Gateway does not pass env vars.
6. Securing your endpoint: For public demo use the default; for production use JWT authorizers, IAM auth, or API keys as appropriate.

## How to test from Postman / browser / curl

1. Deploy and copy the endpoint URL.

2. In Postman: create request (GET/POST) to the URL, send — you’ll see JSON response.

3. In browser console:
```javascript
fetch("https://<api-id>.execute-api.<region>.amazonaws.com/hello")
  .then(r => r.json()).then(console.log).catch(console.error);
```
5. In terminal with curl:
```bash
curl https://<api-id>.execute-api.<region>.amazonaws.com/hello
```
## Alternative approach: AWS SAM
Does the same as above, but using the convenience of AWS SAM to handle boilerplate.

Run:
```bash
sam build
sam deploy --guided
```
When sam `deploy --guided` prompts you, enter the values below or adapt them to your preferences:
* Stack Name [sam-app]: `hello-sam-explicit`

* AWS Region [us-east-1]: `us-west-1` (or your preferred region)

* #Shows you resources to be created: (press Enter)

* Confirm changes before deploy [y/N]: N (or Y if you want to review)

* Allow SAM CLI to create roles with the required permissions? [Y/n]: Y

* Save arguments to _samconfig.toml_ [Y/n]: Y (recommended)

* Parameter DeploymentTimestamp []: 2025-12-01T18:00:00Z

  * **Note**: Change this timestamp each time you want to force a new Deployment resource and have the Stage pick up the new API changes. You can use an ISO timestamp or any string that changes.

* Profile (if prompted) [default]: leave blank or enter your AWS profile name

After you confirm, SAM will package, create or update the stack and print Outputs — the ApiEndpoint value will be shown. Example output will include a URL like:
```plaintext
https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/hello
```

Then test the same ways as above (Postman, browser fetch(), curl).

