#!/bin/sh
set -eu

ACCESS_KEY="$1"
SECRET_ACCESS_KEY="$2"
TASK_DEF="$3"
NETWORK_CONF="$4"
CLUSTER="${5:-test}"
REGION="${6:-eu-north-1}"

aws configure set aws_access_key_id "$ACCESS_KEY"
aws configure set aws_secret_access_key "$SECRET_ACCESS_KEY"
aws configure set region "$REGION"

TASK_ARN="$(aws ecs run-task --cluster "$CLUSTER" --task-definition "$TASK_DEF" --launch-type FARGATE --network-configuration "$NETWORK_CONF" --query "tasks[0].taskArn" --output text)"
aws ecs wait tasks-running --cluster "$CLUSTER" --tasks "$TASK_ARN" > /dev/null
NETWORK_ID="$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$TASK_ARN" --query "tasks[0].attachments[0].details[?name == 'networkInterfaceId'].value" --output text)"
IP="$(aws ec2 describe-network-interfaces --network-interface-ids "$NETWORK_ID" --query "NetworkInterfaces[0].Association.PublicIp" --output text)"

echo "ip=$IP" >> $GITHUB_OUTPUT
