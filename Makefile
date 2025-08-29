# Simple helpers for this repo
STACK ?= my-app
REGION ?= us-east-1
RUNTIME ?= python
APP_NAME ?= my-app
USE_CREATED_ECR ?= true
IMAGE_URI ?=
CERT_ARN ?=
DESIRED ?= 2
NAT_GWS ?= 1
HEALTH ?= /health

TEMPLATE := patterns/ecs-fargate/$(RUNTIME)-service.yml

validate:
	aws cloudformation validate-template --template-body file://$(TEMPLATE)

deploy:
	aws cloudformation deploy \
		--template-file $(TEMPLATE) \
		--stack-name $(STACK) \
		--capabilities CAPABILITY_NAMED_IAM \
		--region $(REGION) \
		--parameter-overrides \
			AppName=$(APP_NAME) \
			UseCreatedEcrRepo=$(USE_CREATED_ECR) \
			ContainerImage=$(IMAGE_URI) \
			DesiredCount=$(DESIRED) \
			HealthCheckPath=$(HEALTH) \
			NatGateways=$(NAT_GWS) \
			CertificateArn=$(CERT_ARN)

delete:
	aws cloudformation delete-stack --stack-name $(STACK) --region $(REGION)
	@echo "Waiting for deletion..."
	aws cloudformation wait stack-delete-complete --stack-name $(STACK) --region $(REGION) || true
