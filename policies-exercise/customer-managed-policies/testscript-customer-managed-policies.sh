#! /bin/bash

# The purpose of this script is to test that a number of AWS actions/commands are permitted
# for the gjsWebsiteAdmin user. If any of the commands fail, an error message for each of them
# is printed to stdout.
#
# The script depends on this policy to exist:
#   arn:aws:iam::975720571991:policy/all-the-policies-customer-policy

# Some resources need to be available for the commands to succeed, and they are created
# temporarily here and then deleted in this script.  They are:
#   IAM group "testscript-temp-group"
# arn:aws:iam::975720571991:policy/all-the-policies

aws iam list-groups-for-user --user-name gjsWebsiteAdmin > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed list-groups-for-user"
fi

aws iam list-attached-user-policies --user-name gjsWebsiteAdmin > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed list-attached-user-policies"
fi
  aws iam list-access-keys --user-name gjsWebsiteAdmin > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed list-access-keys"
fi
  aws iam list-user-policies --user-name gjsWebsiteAdmin  > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed list-user-policies"
fi
  aws iam get-user --user-name gjsWebsiteAdmin  > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed get-user"
fi
  aws iam get-group --group-name aws-cli-capabilities  > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed get-group"
fi

  aws iam get-policy --policy-arn arn:aws:iam::975720571991:policy/all-the-customer-managed-policies > /dev/null
  if [ $? -ne 0 ]; then
    echo "Failed get-policy"
  fi

# Here is the test for create-group, and it does double-duty as creating a temporary
# resource for the delete-group test.
  aws iam create-group --group-name testscript-temp-group  > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed create-group"
fi

# Delete the temporary group
  aws iam delete-group --group-name testscript-temp-group  > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed delete-group"
fi

  aws iam get-user-policy --user-name gjsWebsiteAdmin --policy-name ListAccessKeys_attached-to-user > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed get-user-policy"
fi



