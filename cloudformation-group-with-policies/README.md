# cloudformation-group-with-policies exercise
Tamplate file:  _cf-create-group.yml_

This CloudFormation template creates an IAM group with multiple inline policies attached.

## Preliminaries
* The exercise in *../policies-exercise* should be completed first.
* No other resources are required before deploying this template.

## Steps
1. Go to CloudFormation in the AWS Console
2. Press the _Create stack_ button, choosing _With new resources (standard)_ option
3. In the _Specify template_ section, choose the _Upload a template file_ option
4. Press the _Choose file_ button and select the file _cf-create-group.yml_ from this folder
6. Press the _Next_ button
7. In the _Specify stack details_ section, enter _MyExerciseStack_ in the _Stack name_ field
8. Press the _Next_ button

## Created Resources when complete
1. CloudFormation Stack _MyExerciseStack_
2. IAM Group _devs_ with:
  * No users
  * Policies: 
    * _AmazonS3ReadOnlyAccess_
    * _devs-CustomReadPolicy_

## Cleanup
1. Go to CloudFormation in the AWS Console and delete _MyExerciseStack_
2. Go to IAM Users and delete the group _devs_ if it still exists 
3. Go to IAM Policies and delete the policy _devs-CustomReadPolicy_ if it still exists

## Alternative:  deploy with AWS CLI
It should have been able to create the stack with an AWS CLI command, 
but the one I tried didn't work:

```bash
aws cloudformation deploy --template-file cf-create-group.yml --stack-name MyExerciseStack --parameter-overrides GroupName=devs ManagedPolicyArns="arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"  --capabilities CAPABILITY_NAMED_IAM
```
An alternative would be to try:
```bash
aws cloudformation create-stack --stack-name MyExerciseStack --template-body file://cf-create-group.yml --capabilities CAPABILITY_NAMED_IAM
```

## Additional Notes
### Investigating Failure
When stack creation in AWS CLI fails it doesn't output the reasons.  To get failure details run AWS CLI command:
```bash
aws cloudformation describe-stack-events --stack-name MyExerciseStack
```
### Region mismatch
Make sure you are operating in the same region in both AWS Console and AWS CLI.

I experienced the GOTCHA of creating the stack in AWS Console in _us-east-1_ region (incorrect) and then,
when running the operation in AWS CLI with _us-west-1_ experienced cleanup failures.
It was telling me that the stack I was trying to create was still in rollback state.

Another thing learned along the way is that many resources **do not have regions** but are **global**.  
* _IAM_, _S3_ and _Route53_ resources are global.  You see this in the AWS Console where the _regions_ dropdown
in the upper right changes to `Global` and its options are not selectable. 
* _CloudFormation_ is regional, so stacks are created in specific regions.

Beware of naming conflicts across regions for global resources and even regional ones.
For example:
* Creating IAM resources with the same name in different regions creates problems.
* Similarly, it appears that AWS does not like sharing names for CloudFormation stacks across regions either.

### Two ways of deploying in AWS CLI
* `aws cloudformation deploy` command will tolerate changes to an existing stack by overwriting/updating it with the requested information
* `aws cloudformation create-stack` command will only create a new stack and will fail if a stack with the same name already exists.
