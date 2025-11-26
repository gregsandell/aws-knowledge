#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [--dry-run] STACK_NAME

Options:
  --dry-run   Print actions without performing them.

Environment variables:
  AWS_PROFILE (optional)
  AWS_REGION  (optional)

Examples:
  $0 dev-group-stack
  $0 --dry-run dev-group-stack
EOF
  exit 1
}

# ---- Parse Arguments ----
DRY_RUN=0

if [ $# -eq 0 ]; then
  usage
fi

if [ "$1" = "--dry-run" ]; then
  DRY_RUN=1
  shift
fi

if [ $# -ne 1 ]; then
  usage
fi

STACK_NAME="$1"

# ---- Helper wrappers ----

# aws_cmd executes AWS CLI unless dry-run is enabled
aws_cmd() {
  if [ $DRY_RUN -eq 1 ]; then
    echo "[DRY RUN] aws $*"
  else
    aws "$@"
  fi
}

# echo_run prints an action message and runs the command (or dry-run)
echo_run() {
  echo "$1"
  shift
  aws_cmd "$@"
}

echo
echo "Cleanup script starting for stack: $STACK_NAME"
[ $DRY_RUN -eq 1 ] && echo "Dry-run mode ENABLED: no changes will be made."
echo

# ---- 1. List stack resources ----

echo "Listing resources for stack '$STACK_NAME'..."
resources_json=$(aws cloudformation list-stack-resources --stack-name "$STACK_NAME" --output json) || {
  echo "ERROR: cannot find stack '$STACK_NAME'." >&2
  exit 2
}

group_physical_id=$(echo "$resources_json" | python3 -c "import sys, json; r=json.load(sys.stdin)['StackResourceSummaries']; g=[x for x in r if x['ResourceType']=='AWS::IAM::Group']; print(g[0]['PhysicalResourceId'] if g else '')")

if [ -z "$group_physical_id" ]; then
  echo "No AWS::IAM::Group found in the stack. Will proceed to delete the stack only."
else
  # Extract group name from ARN if needed
  if [[ "$group_physical_id" == arn:aws:*:iam::*:group/* ]]; then
    GROUP_NAME="${group_physical_id##*/}"
  else
    GROUP_NAME="$group_physical_id"
  fi

  echo "Found IAM Group: $GROUP_NAME"
  echo

  # ---- 2. Remove users from the group ----

  echo "Listing users in group '$GROUP_NAME'..."
  users=$(aws iam get-group --group-name "$GROUP_NAME" --query 'Users[].UserName' --output text || echo "")

  if [ -n "$users" ]; then
    echo "Users to remove: $users"
    for u in $users; do
      echo_run "Removing user '$u' from group '$GROUP_NAME'..." iam remove-user-from-group --group-name "$GROUP_NAME" --user-name "$u"
    done
  else
    echo "No users in the group."
  fi
  echo

  # ---- 3. Detach attached managed policies ----

  echo "Listing attached managed policies..."
  attached_policies=$(aws iam list-attached-group-policies --group-name "$GROUP_NAME" --query 'AttachedPolicies[].PolicyArn' --output text || echo "")

  if [ -n "$attached_policies" ]; then
    echo "Managed policies to detach:"
    echo "$attached_policies"
    for p in $attached_policies; do
      echo_run "Detaching managed policy $p ..." iam detach-group-policy --group-name "$GROUP_NAME" --policy-arn "$p"
    done
  else
    echo "No attached managed policies."
  fi
  echo

  # ---- 4. Delete inline group policies ----

  echo "Listing inline group policies..."
  inline_policies=$(aws iam list-group-policies --group-name "$GROUP_NAME" --query 'PolicyNames[]' --output text || echo "")

  if [ -n "$inline_policies" ]; then
    echo "Inline group policies to delete: $inline_policies"
    for pol in $inline_policies; do
      echo_run "Deleting inline policy '$pol'..." iam delete-group-policy --group-name "$GROUP_NAME" --policy-name "$pol"
    done
  else
    echo "No inline policies in group."
  fi
  echo
fi

# ---- 5. Delete the CloudFormation stack ----

echo_run "Requesting deletion for stack '$STACK_NAME'..." cloudformation delete-stack --stack-name "$STACK_NAME"

if [ $DRY_RUN -eq 1 ]; then
  echo
  echo "[DRY RUN] Skipping wait for deletion."
  echo "Dry-run finished. No changes were made."
  exit 0
fi

echo "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" && {
  echo "Stack '$STACK_NAME' deleted successfully."
} || {
  echo "ERROR: Stack deletion failed or timed out." >&2
  exit 3
}

echo
echo "Cleanup completed."
