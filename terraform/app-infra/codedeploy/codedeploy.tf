resource "aws_codedeploy_app" "main" {
  compute_platform = "ECS"
  name             = "${var.project}-hello-world"

  tags = {
    Name = "${var.project}-hello-world"
  }
}

resource "aws_codedeploy_deployment_group" "main" {
  app_name               = aws_codedeploy_app.main.name
  deployment_group_name  = "${var.project}-hello-world"
  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"
  service_role_arn       = aws_iam_role.codedeploy.arn

  # Automatically roll back if the deployment fails or a CloudWatch alarm fires
  # during the canary window.
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  alarm_configuration {
    alarms  = var.alarm_names
    enabled = true
  }

  blue_green_deployment_config {
    deployment_ready_option {
      # Shift traffic immediately once the green tasks pass health checks.
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.cluster_name
    service_name = var.service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.listener_arn]
      }

      target_group {
        name = var.target_group_name_blue
      }

      target_group {
        name = var.target_group_name_green
      }
    }
  }

  tags = {
    Name = "${var.project}-hello-world"
  }
}
