#!/usr/bin/env bash
set -euo pipefail

read -rp "Stack name: " STACK
read -rp "AWS region [us-east-1]: " REGION
REGION=${REGION:-us-east-1}
read -rp "Runtime (python|nodejs|php|go) [python]: " RUNTIME
RUNTIME=${RUNTIME:-python}
read -rp "App name (used for resources) [${STACK}]: " APP_NAME
APP_NAME=${APP_NAME:-$STACK}
read -rp "Use created ECR repo? (true|false) [true]: " USE_CREATED_ECR
USE_CREATED_ECR=${USE_CREATED_ECR:-true}
IMAGE_URI=""
if [[ "$USE_CREATED_ECR" == "false" ]]; then
  read -rp "Existing image URI (e.g. 123.dkr.ecr.${REGION}.amazonaws.com/app:tag): " IMAGE_URI
fi
read -rp "Desired count [2]: " DESIRED
DESIRED=${DESIRED:-2}
read -rp "Health check path [/health]: " HEALTH
HEALTH=${HEALTH:-/health}
read -rp "NAT Gateways (0|1|2) [1]: " NAT_GWS
NAT_GWS=${NAT_GWS:-1}
read -rp "ACM Certificate ARN for HTTPS (optional): " CERT_ARN

TEMPLATE="patterns/ecs-fargate/${RUNTIME}-service.yml"

aws cloudformation deploy \
  --template-file "$TEMPLATE" \
  --stack-name "$STACK" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "$REGION" \
  --parameter-overrides \
    AppName="$APP_NAME" \
    UseCreatedEcrRepo="$USE_CREATED_ECR" \
    ContainerImage="$IMAGE_URI" \
    DesiredCount="$DESIRED" \
    HealthCheckPath="$HEALTH" \
    NatGateways="$NAT_GWS" \
    CertificateArn="$CERT_ARN"
