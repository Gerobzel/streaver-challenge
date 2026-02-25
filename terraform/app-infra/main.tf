locals {
  # When canary weight is 0, scale the canary service down to 0 tasks to save cost.
  canary_desired_count = var.weight_canary == 0 ? 0 : 1
}

module "logging" {
  source  = "./logging/"
  project = var.project

  # Add a new workload here to automatically create a Firehose stream and S3 prefix for it.
  log_groups = {
    "hello-world-stable" = module.workload_stable.log_group_name
    "hello-world-canary" = module.workload_canary.log_group_name
  }
}

module "alb" {
  source = "./alb/"

  project           = var.project
  domain_name       = var.domain_name
  public_vpc_id     = data.aws_vpc.public.id
  public_subnet_ids = data.aws_subnets.public.ids
  private_vpc_id    = data.aws_vpc.private.id
  weight_stable     = var.weight_stable
  weight_canary     = var.weight_canary
}

module "waf" {
  source = "./waf/"

  project = var.project
  alb_arn = module.alb.alb_arn
}

module "dns" {
  source = "./dns/"

  project      = var.project
  domain_name  = var.domain_name
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

module "workload_stable" {
  source = "./workload/"

  name               = "hello-world-stable"
  project            = var.project
  ecr_repository_url = data.aws_ecr_repository.hello_world.repository_url
  image_tag          = var.image_tag_stable
  # cluster_name is used for autoscaling resource_id (service/<cluster_name>/<service_name>)
  cluster_id              = data.aws_ecs_cluster.main.cluster_name
  cluster_arn             = data.aws_ecs_cluster.main.arn
  task_execution_role_arn = data.aws_iam_role.task_execution.arn
  private_subnet_ids      = data.aws_subnets.private.ids
  private_vpc_id          = data.aws_vpc.private.id
  target_group_arn        = module.alb.target_group_arn_stable
  alb_arn                 = module.alb.alb_arn
}

module "workload_canary" {
  source = "./workload/"

  name                     = "hello-world-canary"
  project                  = var.project
  ecr_repository_url       = data.aws_ecr_repository.hello_world.repository_url
  image_tag                = var.image_tag_canary
  desired_count            = local.canary_desired_count
  autoscaling_min_capacity = local.canary_desired_count
  autoscaling_max_capacity = 2
  cluster_id               = data.aws_ecs_cluster.main.cluster_name
  cluster_arn              = data.aws_ecs_cluster.main.arn
  task_execution_role_arn  = data.aws_iam_role.task_execution.arn
  private_subnet_ids       = data.aws_subnets.private.ids
  private_vpc_id           = data.aws_vpc.private.id
  target_group_arn         = module.alb.target_group_arn_canary
  alb_arn                  = module.alb.alb_arn
}

module "monitoring" {
  source = "./monitoring/"

  project      = var.project
  cluster_name = data.aws_ecs_cluster.main.cluster_name
  alb_arn      = module.alb.alb_arn

  # Add an object here for each workload variant to include in the dashboard.
  workloads = [
    {
      name             = "hello-world-stable"
      service_name     = module.workload_stable.service_name
      target_group_arn = module.alb.target_group_arn_stable
      log_group_name   = module.workload_stable.log_group_name
    },
    {
      name             = "hello-world-canary"
      service_name     = module.workload_canary.service_name
      target_group_arn = module.alb.target_group_arn_canary
      log_group_name   = module.workload_canary.log_group_name
    },
  ]
}

module "alerting" {
  source = "./alerting/"

  project      = var.project
  cluster_name = data.aws_ecs_cluster.main.cluster_name
  alb_arn      = module.alb.alb_arn
  alert_email  = var.alert_email

  # Add an object here for each workload variant to include in alerting.
  workloads = [
    {
      name             = "hello-world-stable"
      service_name     = module.workload_stable.service_name
      target_group_arn = module.alb.target_group_arn_stable
    },
    {
      name             = "hello-world-canary"
      service_name     = module.workload_canary.service_name
      target_group_arn = module.alb.target_group_arn_canary
    },
  ]
}
