# starter-cloudformations 
This is an exercise in creating a CloudFormation stack.  In this case the objective of
the stack is to create an IAM group with a list of IAM policies that are used by
typical commands in the AWS CLI, such as:
> aws iam list-group-policies --group-name MyGroup

...without incurring an "Access Denied" error, such as:

_An error occurred (AccessDenied) when calling the ListGroupsForUser operation: User: arn:aws:iam::975720571991:user/gjsWebsiteAdmin is not authorized to perform: iam:ListGroupPolicies on resource: user gjsWebsiteAdmin because no identity-based policy allows the iam:ListGroupPolicies action_
> Note: the straightforward way to give this access would be to simply attach the AWS Managed Policy `AdministratorAccess` to the group _aws-cli-capabilities_, but this exercise helps you learn how to assemble a more limited set of policies, for use in real life, using CloudFormation.  The `AdministrativeACtion` permission is too broad and considered risky except for specialized uses.
## Summary
* The CloudFormation .yml file defines an IAM Group called _DevApplicationsGroup_
* ...which has attached to it a Customer Managed Policy _dev-group-stack_ 

The group policies the stack will include are:
* PowerUserAccess (AWS Managed Policy)
* IAMReadOnlyAccess (AWS Managed Policy)
* A custom list of Inline Policies not covered by the above two, that are added piecemeal in the stack

## The moving parts
* CloudFormation template file: _template.yml_
* ...is used to create a CloudFormation stack called _dev-group-stack_.  
* The stack creates:
  * An IAM Group called _DevApplicationsGroup_
  * A Customer Managed Policy called _dev-group-stack_ which is attached to the group
* Finally, you attach your user (e.g. _gjsWebsiteAdmin_) to the new group _DevApplicationsGroup_ to gain the new permissions.
* Note: make sure you have not left other groups or policies attached to your user that duplicate the ones you just attached.

## Exercise Preparatory Steps
* IAM User _gjsWebsiteAdmin_ and IAM Group _aws-cli-capabilities_ are presumed to exist ( see `policies-exercise`).
* Remove any of the Inline Policies and Customer Managed policies created in the *policies-exercise* before deploying this template.  We assume that the IAM Group _aws-cli-capabilities_ is empty of policies and thus
cannot yet create the target cloudFormation stack.  Next we create some "bootstrapping" policies to enable that.
* Give _aws-cli-capabilities_ temporary superpowers by attaching the _AdministratorAccess_ Customer Managed policy
attach it to the group _aws-cli-capabilities_.  These powers bootstrap the ability to create the CloudFormation stack,
which will in turn create the more limited policies needed for day-to-day operations.
 * The script _bootstrap-policies.sh_ will do all of that for you
* Confirm this step by running the script _testscript.sh_ which checks that the user _gjsWebsiteAdmin_ can run all of the commands that will be needed in the CloudFormation template.

## Create the Stack 'dev-group-stack' and Group 'DevApplicationsGroup'
Use AWS Console or AWS CLI to create a CloudFormation stack called _dev-group-stack_ using the _template.yml_ file in this folder.

If you wish to do it with AWS CLI, use the command:

```bash
aws cloudformation create-stack --template-body file://template.yml --stack-name dev-group-stack --capabilities CAPABILITY_NAMED_IAM
```
> Note: When creating with CLI, the command comes back immediately, but the stack creation continues in the background.  See the **Troubleshooting** for how you can watch its progres.

## Troubleshooting
If stack creation fails you can get the failure reasons in two ways:
1. In AWS Console, go to CloudFormation, select the _dev-group-stack_ stack and go to the _Events_ tab.
2. In AWS CLI, run the command:
```bash
aws cloudformation describe-stack-events --stack-name dev-group-stack --query "StackEvents[?ResourceStatus=='CREATE_FAILED' || ResourceStatus=='UPDATE_FAILED']"
```
## Proof of Success
1. Detach _AdministratorAccess_ from the group _aws-cli-capabilities_ (because we want to prove that our new _dev-group-stack_ is the one providing access, not the temporary superpowers).
2. Go to IAM -> Policies and confirm that the new Managed Policy _dev-group-stack_ exists.
3. Go to IAM -> Groups and confirm that the new Group _DevApplicationsGroup_ exists.
2. Remove user _gjsWebsiteAdmin_ from _aws-cli-capabilities_
2. Add user _gjsWebsiteAdmin_ to group _DevApplicationsGroup_
4. Run the script _testscript-necessary-files.sh_ to check for success.

## Alternatives 
Simply attaching the AWS Managed Policy `AdministratorAccess` to the group _aws-cli-capabilities_ would give
the same access as this template, but it is not a best practice to give out that much power when not needed.
But in this situation you aren't using CloudFormation at all.

## Preparatory steps
* Remove all permissions policies attached to group _aws-cli-capabilities_.

## Steps
1. Attach the AWS Managed Policy `AdministratorAccess` to the group _aws-cli-capabilities_.

## Proof of Success
1. Run the script _testscript-necessary-files.sh_ to check for success.
