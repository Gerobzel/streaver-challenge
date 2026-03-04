# streaver-challenge

A containerized Python service deployed on AWS ECS Fargate, built as part of a technical challenge.

## What it does

- Serves `Hello Streaver!!` on port 8000
- Exposes a healthcheck endpoint on port 8080
- Deployed behind an HTTPS ALB with WAF protection
- Canary and blue/green deployments via AWS CodeDeploy

## Architecture decisions

**Two VPCs (public + private)** — ALB lives in the public VPC, ECS tasks in the private one. Traffic flows inbound only through the load balancer via VPC peering. No NAT gateway needed — ECR image pulls and CloudWatch log shipping use VPC Interface Endpoints (`ecr.api`, `ecr.dkr`, `logs`) and a free S3 Gateway Endpoint.

**Shared vs app infrastructure** — Terraform is split into `shared-infra` (VPCs, ECS cluster, ECR) and `app-infra` (workload, ALB, DNS, monitoring). The two stacks are decoupled using AWS data sources instead of remote state references.

**Canary deployments via CodeDeploy** — A single ECS service uses `deployment_controller = CODE_DEPLOY`. CodeDeploy manages two ALB target groups (`blue`/`green`) and shifts traffic automatically using the `ECSCanary10Percent5Minutes` strategy: 10% to the new version first, then the remaining 90% after 5 minutes if no alarms fire. The strategy is configurable (canary, linear, all-at-once) without infrastructure changes.

**Automatic rollback** — CodeDeploy monitors CloudWatch alarms (`5xx errors`, `unhealthy hosts`) during the canary window. If either fires, the deployment is rolled back to the previous version automatically — no manual intervention required.

**Log archival** — CloudWatch Logs (30-day retention) stream to S3 via Kinesis Firehose (1-year retention, GZIP compressed).

## Pipelines

### Shared Infrastructure (`shared-infra.yml`)

Triggered by changes to `terraform/shared-infra/**`.

- **On pull request**: runs `terraform validate` + `fmt` check, then posts the plan as a PR comment
- **On merge to main**: applies the plan (requires `production` environment approval in GitHub)

Can also be triggered manually from the Actions tab.

### App Infrastructure (`app-infra.yml`)

Triggered by changes to `terraform/app-infra/**`.

- **On pull request**: runs `terraform validate` + `fmt` check, then posts the plan as a PR comment
- **On merge to main**: applies the plan (requires `production` environment approval in GitHub)

Can also be triggered manually from the Actions tab.

### App: Hello World (`app-hello-world.yml`)

Triggered by changes to `apps/hello-world/**`.

- **On pull request**: runs unit tests + Docker build (no push)
- **On merge to main**: runs tests, builds and pushes the image to ECR (git SHA tag + `latest`), then automatically triggers a CodeDeploy deployment and waits for it to complete

## Deployment flow

CodeDeploy executes the following sequence on every merge to main:

```
1. New (green) ECS tasks launched with the new image
2. Health checks pass → 10% of ALB traffic shifted to green
3. 5-minute canary window (CloudWatch alarms monitored)
4. No alarms → remaining 90% shifted to green
5. Blue tasks terminated after 5 minutes
   ↳ Alarm fires at any point → automatic rollback to blue
```

## Deploy order

1. Apply `terraform/shared-infra` (VPCs, cluster, ECR)
2. Push an image to ECR via the `app-hello-world` pipeline (triggers on any push to `apps/hello-world/**`)
3. Apply `terraform/app-infra` (ALB, workload, CodeDeploy, DNS, monitoring)
