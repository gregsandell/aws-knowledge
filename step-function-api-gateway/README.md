# step-function-api-gateway
> Note: I haven't solved/tested this yet.
## Goal
Expose a Step Functions state machine via an API Gateway HTTP API endpoint.

Suggested: use the `step-functions-api-gateway` exercise from this project as a starting point.

## Instructions
**Source**: a ChatGPT query that gave a _Direct REST API → Step Functions (asynchronous)_ example approach.

1. Update `role.yaml` final line to point to the step function ARN you want to invoke.
    * Replace region/account/ARN with your real state machine ARN (or use !GetAtt MyStateMachine.Arn in the same template).

2. Update `api-gateway-integration.yaml` to point to your Step Function ARN in the `stateMachineArn` field.

### What step 2 does:

* The `Uri` points API Gateway to the Step Functions StartExecution action.

* `Credentials` is the role ARN API Gateway assumes to call Step Functions.

* The **request template** constructs the JSON Step Functions expects: a string `input` and `stateMachineArn`.

  * `input` must be a JSON string — the template above escapes the incoming request body into a string.

### Synchronous execution (wait for result)

If you want the API to return the state machine’s output (blocking until it finishes), use `StartSyncExecution` instead of `StartExecution`. Steps:

* Use URI: `arn:aws:apigateway:{region}:states:action/StartSyncExecution`

* Your IAM role must allow `states:StartSyncExecution`.

* The mapping template is similar, and API Gateway will get Step Functions synchronous response (including `status`, `output`).

**Note**: `StartSyncExecution` has timeouts and size limits — for long-running workflows it's not appropriate. For Express Workflows or short runs it can be fine.

## Practical checklist (step-by-step)

1. Create IAM role that API Gateway will assume (trust = `apigateway.amazonaws.com`) and allow `states:StartSyncExecution` on your state machine ARN.

2. Create API Gateway resource + POST method.

3. Configure integration:

    * Type `AWS`

    * Integration URI `arn:aws:apigateway:{region}:states:action/StartSyncExecution`

    * Credentials = role ARN

    * Request mapping template to build `input` (string) and `stateMachineArn`

4. Deploy API and test with `curl`.

5. Add authentication, CORS, and error mappings as needed.
