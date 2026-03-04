module "logging" {
  source  = "./logging/"
  project = var.project

  log_groups = {
    "hello-world" = module.workload.log_group_name
  }
}

module "alb" {
  source = "./alb/"

  project           = var.project
  domain_name       = var.domain_name
  public_vpc_id     = data.aws_vpc.public.id
  public_subnet_ids = data.aws_subnets.public.ids
  private_vpc_id    = data.aws_vpc.private.id
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

module "workload" {
  source = "./workload/"

  name                    = "hello-world"
  project                 = var.project
  ecr_repository_url      = data.aws_ecr_repository.hello_world.repository_url
  image_tag               = var.image_tag
  cluster_id              = data.aws_ecs_cluster.main.cluster_name
  cluster_arn             = data.aws_ecs_cluster.main.arn
  task_execution_role_arn = data.aws_iam_role.task_execution.arn
  private_subnet_ids      = data.aws_subnets.private.ids
  private_vpc_id          = data.aws_vpc.private.id
  target_group_arn        = module.alb.target_group_arn_blue
  alb_arn                 = module.alb.alb_arn
}

module "codedeploy" {
  source = "./codedeploy/"

  project                 = var.project
  cluster_name            = data.aws_ecs_cluster.main.cluster_name
  service_name            = module.workload.service_name
  listener_arn            = module.alb.listener_arn
  target_group_name_blue  = module.alb.target_group_name_blue
  target_group_name_green = module.alb.target_group_name_green

  # Hook the 5xx and unhealthy-host alarms into CodeDeploy's canary window so a
  # bad deployment is automatically rolled back before full traffic is shifted.
  alarm_names = [
    "${var.project}-hello-world-alb-5xx",
    "${var.project}-hello-world-alb-unhealthy-hosts",
  ]
}

module "monitoring" {
  source = "./monitoring/"

  project      = var.project
  cluster_name = data.aws_ecs_cluster.main.cluster_name
  alb_arn      = module.alb.alb_arn

  workloads = [
    {
      name             = "hello-world"
      service_name     = module.workload.service_name
      target_group_arn = module.alb.target_group_arn_blue
      log_group_name   = module.workload.log_group_name
    },
  ]
}

module "alerting" {
  source = "./alerting/"

  project      = var.project
  cluster_name = data.aws_ecs_cluster.main.cluster_name
  alb_arn      = module.alb.alb_arn
  alert_email  = var.alert_email

  workloads = [
    {
      name             = "hello-world"
      service_name     = module.workload.service_name
      target_group_arn = module.alb.target_group_arn_blue
    },
  ]
}
