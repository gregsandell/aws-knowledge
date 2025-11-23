# IAM User Policy exercise

I created this as a proof of concept of my understanding
how users, groups and policies work.

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

> 
## Exercise One steps
1. Create the six policies in the _policies_ folder and
add each individually to the group _aws-cli-capabilities_. Do this by copying the
full JSON content of each policy file and pasting it into the JSON editor
for the Add permissions > Create inline policy workflow
2. Run the script _testscript.sh_ in the terminal while logged in as user gjsWebsiteAdmin.
3. The script is successful if it completes with no outut.  Otherwise, there
will be error messages indicating which commands failed.

## Cleanup prep for Exercise Two
1. Detach all six policies from the group _aws-cli-capabilities_.
2. Do **not** detach the policy _ListAccessKeys_attached-to-user_ from user _gjsWebsiteAdmin_.

## Exercise Two steps
1. Attach the policy _all_policies.json_ to the group _aws-cli-capabilities_, using the 
same workflow as above.
2. Repeat the run of the script _testscript.sh_ and expect the same outcomes as before.
