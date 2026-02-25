data "aws_region" "current" {}

# Service Connect Namespace — one per workload variant, scoped to var.name
resource "aws_service_discovery_http_namespace" "main" {
  name = "${var.project}-${var.name}"

  tags = {
    Name = "${var.project}-${var.name}"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.project}/${var.name}"
  retention_in_days = 30

  tags = {
    Name = "${var.project}-${var.name}"
  }
}

# Security Group for ECS tasks
resource "aws_security_group" "main" {
  name   = "${var.project}-${var.name}"
  vpc_id = var.private_vpc_id

  ingress {
    description = "App port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Healthcheck port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.name}"
  }
}

# Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project}-${var.name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name  = var.name
      image = "${var.ecr_repository_url}:${var.image_tag}"

      portMappings = [
        {
          name          = "http"
          containerPort = 80
          protocol      = "tcp"
        },
        {
          name          = "healthcheck"
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:8080')\" || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = var.name
        }
      }
    }
  ])

  tags = {
    Name = "${var.project}-${var.name}"
  }
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "${var.project}-${var.name}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count

  # Roll back automatically if the new deployment fails health checks repeatedly.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  health_check_grace_period_seconds = 60

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.name
    container_port   = 80
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 0
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.main.id]
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn

    service {
      port_name = "http"
      client_alias {
        port = 80
      }
    }
  }

  tags = {
    Name = "${var.project}-${var.name}"
  }
}
