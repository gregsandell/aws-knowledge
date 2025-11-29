#!/usr/bin/env bash
POLICY_FILE=necessary-policies.json
POLICY_NAME=starter-policies
TARGET_GROUP=aws-cli-capabilities

function ynquery()
{
    echo -n "$@" '[y/n] ' ; read ans
    case "$ans" in
        y*|Y*) return 0 ;;
        *) return 1 ;;
    esac
}

echo "Info: "
echo "This script will create (or clean up) policy $POLICY_NAME from file $POLICY_FILE and attaching to group $TARGET_GROUP"
echo "$TARGET_GROUP must already exist."
echo " "
echo "Current status: is there a policy named $POLICY_NAME already existing? Checking..."
count=`aws iam list-policies --scope Local --no-paginate --output json | jq -r "[.Policies[] | select(.PolicyName==\"${POLICY_NAME}\")] | length"`

if [ $count -gt 0 ]; then # at least one policy with that name exists
  policyArns=`aws iam list-policies --scope Local --output json | jq -r --arg NAME "$POLICY_NAME" '[.Policies[] | select(.PolicyName==$NAME)][0].Arn'`
  echo " "
  echo $policyArns
  echo "Yes a policy \"$POLICY_NAME\" already exists with arn \"${policyArns}\".  You will have to remove it first before creating a new one with that name."
  ynquery "Remove the existing policy ${POLICY_NAME} and continue?"
  if [ $? -eq 0 ]; then # yes please remove the policy
    echo " "
    echo "Before you remove it, you have to check if it is attached to any group (or other entity).  Checking.."
    listedEntities=`aws iam list-entities-for-policy --policy-arn $policyArns `

    if [ $? -eq 0 ]; then # There are listed entities
      attachedEntities=`echo $listedEntities | jq -r '.PolicyGroups[].GroupName'`
      echo " "
      echo $listedEntities
      echo " "
      ynquery "Do there appear to be attached entities in the above output? Answer 'y' to delete them, or answer 'n' to go on."
      if [ $? -eq 0 ]; then
        for entity in $attachedEntities; do
          echo "Detaching policy from group $entity"
          aws iam detach-group-policy \
            --group-name $entity \
            --policy-arn $policyArns
          if [ $? -ne 0 ]; then
            echo "Failed to detach policy from group $entity"
            exit 1
          fi
          exit 1
        done
      else
        echo " "
        echo "Ok, not detaching policy.  Resuming."
        echo " "
        ynquery "Remove policy \"$POLICY_NAME\" from entity \"$TARGET_GROUP\" now?"
        if [ $? -eq 0 ]; then
          aws iam delete-policy --policy-arn $policyArns
        else
          echo " "
          echo "Ok, not moving on to remove it.  Goodbye."
          exit 0
        fi
      fi
    fi
  else
    echo "Ok, not removing policy.  Goodbye."
    exit 0
  fi
else
  echo "No existing policy named $POLICY_NAME found.  Proceeding to create it."
  arn=`aws iam create-policy --policy-name $POLICY_NAME --policy-document file://${POLICY_FILE} | jq -r '.Policy.Arn'`
  echo Created policy with ARN "${arn}"
  echo " "
  echo "Attaching policy $POLICY_NAME to group $TARGET_GROUP"
  aws iam attach-group-policy \
    --group-name $TARGET_GROUP \
    --policy-arn $arn
  if [ $? -ne 0 ]; then
    echo "Failed to attach policy $POLICY_NAME to group $TARGET_GROUP"
  else
    echo "Successfully attached policy $POLICY_NAME to group $TARGET_GROUP"
  fi
fi
exit

