# serverless-hellowWorld - option1-aws-sam
1. Install the SAM CLI.  Best not to use Homebrew, because it can get out of date.  Follow the instructions at https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html
2. In this folder, run the command: 
   ```bash
   sam build
   ```
3. Then run the command:
   ```bash
   sam deploy --guided    
   ```
4. Follow the prompts to deploy the application.  You can accept the defaults for most prompts (??? but make sure to set a unique S3 bucket name when prompted for the S3 bucket to use for deployment artifacts.???)
5. After deployment is complete, note the API endpoint URL output by the deployment process, which will look like: `https://<api-id>.execute-api.<region>.amazonaws.com/hello`
6. Test the deployed application by running the command:
   ```bash
   curl <API_ENDPOINT_URL>/hello
   ```
   replacing `<API_ENDPOINT_URL>` with the actual URL from the previous step.
7. Or browser fetch():
```bash
   fetch(<API_ENDPOINT_URL>)
        .then(r => r.json())
        .then(console.log)
        .catch(console.error);
```
8. Or in Postman, create a GET request to `<API_ENDPOINT_URL>/hello` and send the request.
7. You should see a JSON response with a greeting message.
8. To clean up the deployed resources, run the command:
   ```bash
   sam delete
   ```
9. Confirm the deletion when prompted.
10. This will remove all resources created during the deployment.

## Observations
When I ran it:
1. It creates SAM configuration file `samconfig.toml` in the current folder.
    * .toml stands for "Tom's Obvious, Minimal Language"
2. it created a deployment S3 bucket called `aws-sam-cli-managed-default-samclisourcebucket-nharzudogzib`
3. Also added by the stack:

| Id                                      |      Resource Type       |                                                                     Comment 
   |-----------------------------------------|:------------------------:|----------------------------------------------------------------------------:|
   | HelloFunctionHelloApiPermission         | AWS::Lambda::Permission  | Allows the API Gateway to invoke the lambda function. See next outline item |
   | HelloFunctionRole                       |      AWS::IAM::Role      |                The execution role that allows the lambda to execute itself. |
   | HelloFunction                           |  AWS::Lambda::Function   |                                                                             |
   | ServerlessHttpApiApiGatewayDefaultStage | AWS::ApiGatewayV2::Stage |  "stage" means like _prod_, _dev_, _test_ etc. This defaults to _$default_. |
   | ServerlessHttpApi                       |  AWS::ApiGatewayV2::Api  |                                Shows as: id of _dkks4ispyc_, route _/hello_ |
4. The lambda permission is located here in the AWS Console: 
   * Lambda -> Functions -> hello-sam-function -> Configuration tab -> Permissions (left rail) -> Resource-based policy statements card
5. The SAM script created this changeset: `arn:aws:cloudformation:us-west-1:975720571991:changeSet/samcli-deploy1764615364/dd9fc6ef-df3c-4541-ae25-dd2cc5f999ea`                      
5. So the url should be: `https://dkks4ispyc.execute-api.us-west-1.amazonaws.com/hello`    
6. `curl` test worked for me and gave response:            
```json
{
   "message":"Hello, World!",
   "receivedAt":"2025-12-01T19:28:24.021Z",
   "eventSummary":{
      "method":"GET","path":"/hello"
   }
}
```      
## Summary of moving parts
* The lambda function
  * which is given a permission and a role
* An ServerlessHttpApi
  * which has a default stage

                           
     
