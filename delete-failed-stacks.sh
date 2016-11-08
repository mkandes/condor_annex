#!/bin/bash
#
# delete-failed-stacks.sh
#
# Run this script with cron to periodically remove AWS CloudFormation
# Stacks that have a DELETE_FAILED StackStatus. This script is intended
# to be used in conjuction with condor_annex, which occasionally fails 
# to delete its CloudFormation Stacks when it hits a known race 
# condition during annex shutdown. If these Stacks are not cleaned up 
# properly and are allowed to accumulate over time, then a condor_annex
# user may eventually exceed their AWS account limit on the number of 
# CloudFormation Stacks allowed to exist simultaneously. This will 
# prevent a user from being able to create new annexes until the Stack 
# limit is met. The default Stack limit is currently 200 [1].
#
# [1] 
#
# http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html

DEFAULT_REGION='us-east-1'

if [ -n "$1" ]; then
   case "$1" in 
      -r|--region) 
         shift
         REGION="$1"
         ;;
      *) 
         echo 'Usage: delete-failed-stacks.sh [-r|--region]' 2>&1
         exit 1
         ;;
   esac
else
   REGION=$DEFAULT_REGION
fi

DELETE_FAILED_LIST=$(aws cloudformation describe-stacks \
      --region $REGION \
      --query 'Stacks[?StackStatus==`DELETE_FAILED`].StackName' \
      --output text
)

if [ -n "$DELETE_FAILED_LIST" ]; then
   for STACK_NAME in $DELETE_FAILED_LIST; do
      aws cloudformation delete-stack \
         --region $REGION \
         --stack-name $STACK_NAME
   done
fi
