# ---------------------------------------------------------------------------
# Data sources for shared infrastructure created by shared-infra/.
# app-infra looks up resources by the naming convention "${var.project}-*"
# so shared-infra never needs to be touched again after the initial apply.
# ---------------------------------------------------------------------------

data "aws_vpc" "private" {
  tags = {
    Name = "${var.project}-private"
  }
}

data "aws_vpc" "public" {
  tags = {
    Name = "${var.project}-public"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.private.id]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.public.id]
  }
}

data "aws_ecs_cluster" "main" {
  cluster_name = "${var.project}-cluster"
}

data "aws_iam_role" "task_execution" {
  name = "${var.project}-ecs-task-execution"
}

data "aws_ecr_repository" "hello_world" {
  name = "${var.project}/hello-world"
}
