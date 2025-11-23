#! /bin/bash
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
  aws iam get-user-policy --user-name gjsWebsiteAdmin --policy-name ListAccessKeys_attached-to-user > /dev/null
if [ $? -ne 0 ]; then
  echo "Failed get-user-policy"
fi
