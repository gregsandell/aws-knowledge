# IAM User/Group Inline Policy exercise

I created this as a proof of concept of my understanding
how policies can be attached to an IAM Group (or User) to enable the execution of actions.  We will
use the word "entity" stand for Group or User.

Two methods of attaching are explored here:
1. Attaching a policy to an entity is known as an "inline policy."
It is attached exclusively to that entity, and cannot be reused. Typically, it is 
used for short-term purposes and not very practical for serious projects.
2. "Customer-Managed policies" are policies that live in the same area of AWS Managed Policies live, and therefore are resuable.

In this exercise we will work with Inline Policies first, and then Customer-Managed policies.
## Preliminaries
These requirements should be satisfied:
1. gjsWebsiteAdmin IAM user exists
2. Attach the policy below to user gjsWebsiteAdmin and give it the name _ListAccessKeys_attached-to-user_:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:ListAccessKeys",
      "Resource": "*"
    }
  ]
}
```
3. Create an IAM group named _aws-cli-capabilities_ and add user gjsWebsiteAdmin to this group.

# Exercise One
Folder: _inline-policies_
## Exercise One steps
1. Create all the policies in the _inline-policies_ folder by adding each individually to the group _aws-cli-capabilities_ through the _Permissions_ tab. Do this by copying the
full JSON content of each policy file and pasting it into the JSON editor
for the Add permissions > Create inline policy workflow.  You do this once
for each of the polic files in the folder.
2. Run the script _testscript-inline-policies.sh_ in the terminal while logged in as user gjsWebsiteAdmin.
3. The script is successful if it completes with no output.  Otherwise, there
will be error messages for each command that failed.

## Cleanup after Exercise One
This is needed to prep for Exercise Two.
1. Detach all eleven policies from the group _aws-cli-capabilities_.
2. Delete the IAM Group _testscript-temp-group_ if it exists.
2. Do **not** detach the policy _ListAccessKeys_attached-to-user_ from user _gjsWebsiteAdmin_.

**Exercise Two** will show how the same policies as Exercise One can be entered into a single file and attached to an entity, eliminating the tedium of doing one policy at a time.

# Exercise Two
Folder: same as Exercise One: _inline-policies_
## Exercise Two steps
1. _all_inline_policies.json_ is already made for you.  Attach it to the group _aws-cli-capabilities_, using the 
same workflow as above.
2. in the _Policy Details_ field, give it the name _all-the-inline-policies_.
2. Repeat the run of the script _testscript-inline-policies.sh_ and expect the same outcomes as before.

## Cleanup after Exercise Two
This is needed to prep for Exercise Three.
1. Detach the policy _all-the-inline-policies_ from the group _aws-cli-capabilities_
2. Do not delete the group _aws-cli-capabilities_.

Exercise Three creates the same set of policies as Customer-Managed Policies,
in the same folder as before (`inline-policies`). Additionally we will add some
policies that work for actions that work **only** with Customer-Managed Policies.
These additional polices are in the `customer-managed-policies` folder.

# Exercise Three
Folder: _customer-managed-policies_

This is an exercise in creating Customer-Managed Policies as opposed to Inline Policies.
## Exercise Three steps
1. _customer_managed_policies.json_ is already made for you.  On the AWS IAM page in the
AWS Console, select _Policies_ from the left rail.  Press _Create Policy_.
2. In _Select a Service_, choose `IAM`.
3. In _Policy Editor_, press _JSON_ and overwrite the contents with the contents of _all_customer_managed_policies.json_. Press _Next_.
4. in the _Policy Details_ field, give it the name `_`all-the-customer-managed-policies` and press _Create_.
5. Once it's created, notice that by typing `all` into the search field, that our new policy appears as one of the policies.
6. Go to the IAM User Group _aws-cli-capabilites_, _Permissions_ tab, press _Add Permission_ with the **_Attach Policies_ choice**.
7. Find our policy using the approach in step 5, check its box and click _Attach Policies_.
2. Run the script _testscript-customer-managed-policies.sh_ in the `customer-managed-policies` folder and expect the same outcomes as before.

# Additional Notes
* The cleanup steps could be accomplished with AWS CLI commands, but it gets more complicated.
  You have to detach policies from groups and users before deleting them.  See the CLI commands
  _list-group-policies_, _delete-group-policy_, _list-attached-group-policies_, _get-group_, _remove-user-from-group_, and _delete-group_.
* The scripts mentioned in these exercises assume your AWS CLI session is logged in with user `gjsWebsiteAdmin`.

## For a permanent set of policies
See the `starter-cloudformations/application-developers` CloudFormation template
that creates an IAM Group with a sensible set of AWS managed policies suitable for application developers.
