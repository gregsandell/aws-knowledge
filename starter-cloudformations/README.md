# starter-cloudformations
This repository contains a collection of starter AWS CloudFormation templates that I plan to be used as a foundation for building AWS projects. 

## application-developers
* "creates an IAM Group for your developers and attaches a sensible set of AWS managed policies suitable for performing AWS Console and CLI tasks for application developers."
* "a conservative, practical starter set that gives developers broad service access (but not ability to manage IAM users/groups), plus read-only IAM access so they can view identity configuration."

Default Policies included with this:
* AmazonS3FullAccess
* AmazonRDSFullAccess
* CloudWatchFullAccess
* IAMReadOnlyAccess

Built-in AWS policies that one might add for a more powerful set:
* AmazonDynamoDBFullAccess
* AmazonEC2FullAccess
* AWSLambda_FullAccess

## Usage
* Deploy with AWS CLI:
```bash
aws cloudformation create-stack --template-body file://template.yml --stack-name dev-group-stack --capabilities CAPABILITY_NAMED_IAM
```

TODO: Discover if my application-developers stack creates "all the permissions I need" for AWS app development, by: (1) Create my application-developers template; (2) delete the policy created by my-default-policy; (3) Run the application-developers template to create again a new group with a new name; if this succeeds, all is well
