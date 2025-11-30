#! /bin/bash
# TODO Rewrite this using variables and loop
#
# The purpose of this script is to test that a number of AWS actions/commands are permitted
# for as given user. If any of the commands fail, an error message for each of them
# is printed to stdout.

STARTER_POLICY=arn:aws:iam::975720571991:policy/starter-policies # Must be pre-existing
GJS_USER=gjsWebsiteAdmin # Must be pre-existing
CLI_CAPABILITIES_GROUP=aws-cli-capabilities # Must be pre-existing
TEMP_GROUP=testscript-temp-group # Created and deleted in this script

aws iam list-groups-for-user --user-name $GJS_USER > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed list-groups-for-user"
fi

aws iam list-attached-user-policies --user-name $GJS_USER > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed list-attached-user-policies"
fi
  aws iam list-access-keys --user-name $GJS_USER > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed list-access-keys"
fi
  aws iam list-user-policies --user-name $GJS_USER  > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed list-user-policies"
fi
  aws iam get-user --user-name $GJS_USER  > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed get-user"
fi
  aws iam get-group --group-name $CLI_CAPABILITIES_GROUP  > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed get-group"
fi

  aws iam get-policy --policy-arn $STARTER_POLICY > /dev/null
  if [ $? -ne 0 ]; then
    echo "Failed get-policy"
  fi

# Here is the test for create-group, and it does double-duty as creating a temporary
# resource for the delete-group test.
  aws iam create-group --group-name $TEMP_GROUP  > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed create-group"
fi

# Note: put-group-policy adds an inline policy (i.e. not Customer Managed Policy) to the named group.
aws iam put-group-policy \
  --group-name $TEMP_GROUP \
  --policy-name AllowListGroupsForUser \
  --policy-document '{
    "Version":"2012-10-17",
    "Statement":[{"Effect":"Allow","Action":"iam:ListGroupsForUser","Resource":"*"}]
  }'
if [ $? -ne 0 ]; then
  echo "Failed put-group-policy"
fi

# delete-group-policy removes an inline policy (i.e. not Customer Managed Policy) from the named group.
aws iam delete-group-policy \
  --group-name $TEMP_GROUP \
  --policy-name AllowListGroupsForUser
if [ $? -ne 0 ]; then
  echo "Failed delete-group-policy"
fi

# Delete the temporary group
  aws iam delete-group --group-name $TEMP_GROUP  > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed delete-group"
fi

aws iam list-attached-group-policies --group-name $CLI_CAPABILITIES_GROUP > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed list-attached-group-policies"
fi
aws iam list-group-policies --group-name $CLI_CAPABILITIES_GROUP > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed list-group-policies"
fi



# detach-group-policy is for detaching a Customer Managed Policy (i.e. not an Inline Policy) from a group.
#aws iam detach-group-policy \
#    --group-name MyDeveloperGroup \
#    --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# TODO Create necessary resources and edit the test below to get it working
#aws iam get-group-policy \
#  --group-name foo-group \
#  --policy-name AllowListGroupsForUser
