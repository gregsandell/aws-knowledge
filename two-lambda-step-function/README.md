# two-lambda-step-function

**Goal**: 
* lambdas 1 & 2 run in sequence in a step function
* lambda 1 produces output which is passed as input to lambda 2

## Concept

* A **Step Functions state machine** coordinates steps (Tasks).

* Use the **Lambda service integration** so Step Functions **invokes Lambdas synchronously** (<-- change this?) and receives their returned JSON.

* Use `ResultPath` and `Payload.$` to pass & shape the input/output between steps.

* Give the state machine an IAM role that can `lambda:InvokeFunction`.
## Ready-to-deploy SAM template (template.yaml)
Notes on the _template.yaml_ file in this folder:
* `Resource: "arn:aws:states:::lambda:invoke"` is the Step Functions **service integration** for synchronous Lambda invocation. Step Functions will wait for the Lambda result and place it under the `Payload` field of the task result.

* `Payload.$` and `fromLambdaA.$` are JSON Path expressions that pass and extract data between steps.

* `ResultPath` stores the task result into the state input under a key (e.g., `$.lambdaAResult`).

## Lambda handlers
Directories lambda-a and lambda-b contain the two lambdas.

If you use any npm packages, include package.json and run npm install in each lambda folder before packaging.

lambda-a will produce:
```json
{
  "number": 42,
  "note": "This number will be passed to LambdaB"
}
``` 

## Deploy & run
1. Build and deploy:
```bash
sam build
sam deploy --guided --capabilities CAPABILITY_NAMED_IAM
```
Enter stack name, region, allow IAM creation, and optionally set `DeploymentTimestamp` if you use it for forcing deployments.
2. After deployment you’ll get the State Machine ARN in outputs. Start an execution:
```bash
aws stepfunctions start-execution \
  --state-machine-arn <STATE_MACHINE_ARN> \
  --name exec-$(date +%s) \
  --input '{"foo":"bar"}'
```
3. To check execution status:
```bash
aws stepfunctions describe-execution --execution-arn <EXECUTION_ARN>
```
4. To view the visual execution flow, open the **Step Functions** console → State machines → select your state machine → Executions → click an execution to inspect input/output and step-by-step data.

## (Figure out where this should go)
* `$.lambdaAResult.Payload` is the return value of LambdaA

* `$.lambdaAResult.Payload.number` extracts the **number** field

* The Step Function passes it into LambdaB as `event.numberFromA`
* lambda-b now receives:
```plaintext
{
  "numberFromA": 42,
  "input": { ...the original execution input + lambdaAResult... }
}
```

## What the final workflow looks like
1. Step Function starts with your input:
```json
{
  "foo": "bar"
}
```
2. LambdaA receives this input:

```plaintext
-> returns { "number": 42 }
```
3. Step Function stores that at `$.lambdaAResult.Payload.number`
4. Step Function passes that number to LambdaB as:
```json
{
    "numberFromA": 42,
    "input": { ... }
}
```
5. LambdaB uses it however you want (math, logic, etc.)

## IAM notes

* The Step Functions execution role must allow `lambda:InvokeFunction` for each Lambda (we created that role in the SAM template).

* Each Lambda needs its own execution role (SAM creates default roles with CloudWatch logging permissions). If Lambda functions need to access other AWS services, add permissions to their roles.

## Synchronous vs asynchronous invocation

* Using `arn:aws:states:::lambda:invoke` performs a **synchronous** invocation (`RequestResponse`) and Step Functions waits for the result. The Lambda return becomes `Payload`.

* There are other integrations (e.g., `invoke.waitForTaskToken`) useful for long-running workflows or callbacks, but synchronous is simplest for sequential short tasks.

## Observability & testing

* Use CloudWatch Logs (SAM-created roles include that) to inspect each Lambda’s logs.

* Step Functions console shows per-state inputs/outputs and history — very handy for debugging.

* Consider adding `Task HeartbeatSeconds` or `TimeoutSeconds` to detect stuck tasks.
