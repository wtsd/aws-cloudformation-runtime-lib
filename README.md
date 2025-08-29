# AWS CloudFormation Quickstarts -- Multi-Runtime (Python, PHP, Node.js, Go)

Kickstart CloudFormation templates to easily **clone, tweak, and deploy**.

Note-to-self: Check the latest CVE.

Each template provisions:
- A new **VPC** (2 AZs) with public & private subnets (optional 0/1/2 NAT Gateways)
- **Application Load Balancer (ALB)** with HTTP (and HTTPS if there is an ACM cert ARN)
- **ECS Fargate** cluster, **ECR** repo, **CloudWatch Logs**, IAM roles
- An ECS **Service** and **TaskDefinition** for your containerized app
- Optional **target-tracking autoscaling** on CPU

> [!!!] **Costs**: NAT Gateways, ALB, and Fargate tasks incur charges. Prefer `NatGateways=0` for test sandboxes, staging env or `1` for cost-balanced setups.

---

## Repository layout

```
patterns/
  ecs-fargate/
    python-service.yml     # default port 8000
    nodejs-service.yml     # default port 3000
    php-service.yml        # default port 80 (use nginx+php-fpm image) TODO: Look for something better
    go-service.yml         # default port 8080
scripts/
  deploy.sh                # interactive deploy helper (prompts)
  delete-stack.sh          # delete helper
Makefile                   # quick commands
docs/
  REFERENCES.md            # links to relevant AWS docs -- might need to be reviewed
```

## Prerequisites

- AWS account & credentials configured (`aws configure`)
- An **ECR Docker image** for your app (or let the stack create one and push to it)
- AWS CLI v2 installed
- In my examples there is `us-east-1` region, customize or use env var

## Quickstart (copy & deploy)

1) **Pick a template** for your runtime from `patterns/ecs-fargate/`.

2) **(Option A)** Let the stack create an ECR repo and use the `:latest` tag:
```bash
make deploy RUNTIME=python STACK=my-python APP_NAME=my-python USE_CREATED_ECR=true REGION=us-east-1
```
Then build & push to the created repo (see output `EcrRepositoryUri`):
```bash
DOCKER_IMAGE_NAME=my-python
AWS_ACCOUNT=<ACCOUNT>
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com

docker build -t ${DOCKER_IMAGE_NAME}:latest .
docker tag ${DOCKER_IMAGE_NAME}:latest <ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com/${DOCKER_IMAGE_NAME}:latest
docker push <ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com/${DOCKER_IMAGE_NAME}:latest

# update the stack to deploy the new image
make deploy RUNTIME=python STACK=my-python APP_NAME=my-python USE_CREATED_ECR=true REGION=us-east-1
```

3) **(Option B)** Use an **existing** image URI:
```bash
make deploy RUNTIME=nodejs STACK=my-node APP_NAME=my-node USE_CREATED_ECR=false IMAGE_URI=${AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/my-node:1.0.0   REGION=us-east-1
```

4) **Get the URL**: after completion, open `http://$(AlbDnsName)/` from stack outputs.  
HTTPS: pass `CertificateArn=<your-arn>` to enable port 443.

## Minimal parameters

- `AppName` -- logical name for resources (e.g., `my-node`)
- `UseCreatedEcrRepo` -- `true` to create and use `:latest` from a new ECR repo
- `ContainerImage` -- required if `UseCreatedEcrRepo=false`
- `ContainerPort` -- default per language template (override if needed)
- `DesiredCount` -- number of tasks (default 2)

Advanced (optional): `NatGateways` (`0|1|2`), `HealthCheckPath`, `Cpu`, `Memory`, `AllowedHttpCidr`, autoscaling knobs, and subnet CIDRs. Read the AWS docs.

## Makefile shortcuts

```bash
# validate template
make validate RUNTIME=python
# deploy
make deploy RUNTIME=go STACK=my-go APP_NAME=my-go REGION=us-east-1
# delete
make delete STACK=my-go REGION=us-east-1
```

Variables: `STACK`, `REGION`, `RUNTIME` (python|php|nodejs|go), `APP_NAME`, `USE_CREATED_ECR` (true|false), `IMAGE_URI`, `CERT_ARN`, `DESIRED`, `NAT_GWS`, `HEALTH`.

## Runtime notes:

- **Python**: expose your web app on `$PORT` (default 8000). Example: `gunicorn app:app --bind 0.0.0.0:$PORT`.
- **Node.js**: expose Express/Koa/NestJS on `$PORT` (default 3000).
- **PHP**: use an image that bundles **nginx + php-fpm** and listens on port 80 (or change `ContainerPort`).
- **Go**: build a static binary and listen on `$PORT` (default 8080).

## Clean up

```bash
make delete STACK=my-node REGION=us-east-1
```

## Security & production hardening (quick tips)

- Restrict `AllowedHttpCidr` to trusted ranges or put ALB behind WAF
- [!] Add HTTPS by providing an ACM certificate ARN (`CertificateArn` param)
- Use Secrets Manager or SSM Parameter Store in your task (add IAM to `TaskRole`)
- Consider `NatGateways=2` for HA or `0` for ultra-low-cost test envs

See `docs/REFERENCES.md` for authoritative AWS documentation links.
