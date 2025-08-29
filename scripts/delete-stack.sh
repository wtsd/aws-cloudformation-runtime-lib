#!/usr/bin/env bash
set -euo pipefail
STACK=${1:-}
REGION=${2:-us-east-1}
if [[ -z "$STACK" ]]; then
  echo "Usage: $0 <stack-name> [region]"; exit 1
fi
aws cloudformation delete-stack --stack-name "$STACK" --region "$REGION"
aws cloudformation wait stack-delete-complete --stack-name "$STACK" --region "$REGION" || true
echo "Deleted $STACK"
