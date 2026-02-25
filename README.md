# streaver-challenge

A containerized Python service deployed on AWS ECS Fargate, built as part of a technical challenge.

## What it does

- Serves `Hello World` on port 80
- Exposes a healthcheck endpoint on port 8080
- Deployed behind an HTTPS ALB with WAF protection
- Supports canary deployments via ALB weighted routing

## Architecture decisions

**Two VPCs (public + private)** — ALB lives in the public VPC, ECS tasks in the private one. Traffic flows inbound only through the load balancer.

**Shared vs app infrastructure** — Terraform is split into `shared-infra` (VPCs, ECS cluster, ECR) and `app-infra` (workloads, ALB, DNS, monitoring). The two stacks are decoupled using AWS data sources instead of remote state references.

**Canary deployments** — Two ECS services (stable + canary) share the same ECR repository but run different image tags. Traffic is split at the ALB listener level. Setting canary weight to 0 scales the canary service down to zero tasks.

**Auto-healing** — ECS deployment circuit breaker is enabled with automatic rollback. An EventBridge rule fires an SNS alert if a rollback is triggered.

**Log archival** — CloudWatch Logs (30-day retention) stream to S3 via Kinesis Firehose (1-year retention, GZIP compressed).

## Pipelines

### Shared Infrastructure (`shared-infra.yml`)

Triggered by changes to `terraform/shared-infra/**`.

- **On pull request**: runs `terraform validate` + `fmt` check, then posts the plan as a PR comment
- **On merge to main**: applies the plan (requires `production` environment approval in GitHub)

Can also be triggered manually from the Actions tab.

### App: Hello World (`app-hello-world.yml`)

Triggered by changes to `apps/hello-world/**`.

- **On pull request**: runs unit tests + Docker build (no push)
- **On merge to main**: runs tests, builds the image, and pushes two tags to ECR — the git SHA and `latest`

The git SHA tag is printed in the job summary for use in canary deployments.

### Canary Deployment (`deploy-canary.yml`)

Triggered manually from the Actions tab. Takes four inputs:

| Input | Description | Default |
|---|---|---|
| `stable_image_tag` | Image tag for the stable service | `latest` |
| `stable_weight` | % of traffic routed to stable | `100` |
| `canary_image_tag` | Image tag for the canary service | `latest` |
| `canary_weight` | % of traffic routed to canary | `0` |

After applying, it waits for both ECS services to stabilize before reporting success.

**Typical canary promotion flow:**

```
# 1. Start canary at 10%
stable_image_tag=latest  stable_weight=90
canary_image_tag=abc1234 canary_weight=10

# 2. Increase to 50%
stable_weight=50  canary_weight=50

# 3. Fully promote
stable_image_tag=abc1234 stable_weight=100
canary_image_tag=abc1234 canary_weight=0   <- canary scales to zero
```

**Rollback** — set `canary_weight=0` at any point to drain canary traffic and scale it down.

## Deploy order

1. Apply `terraform/shared-infra` (VPCs, cluster, ECR)
2. Push an image to ECR via the `app-hello-world` pipeline
3. Apply `terraform/app-infra` (ALB, services, DNS, monitoring)
