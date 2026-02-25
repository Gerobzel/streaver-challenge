locals {
  # Extract the suffix portions of the ARNs needed to build the ALBRequestCountPerTarget resource label.
  # ALB ARN format:  arn:aws:...:loadbalancer/app/<name>/<id>  → app/<name>/<id>
  # TG ARN format:   arn:aws:...:targetgroup/<name>/<id>        → targetgroup/<name>/<id>
  alb_suffix                 = replace(var.alb_arn, "/^.+:loadbalancer\\//", "")
  tg_suffix                  = replace(var.target_group_arn, "/^.+:/", "")
  alb_request_resource_label = "${local.alb_suffix}/${local.tg_suffix}"
}

# Register the ECS service as a scalable target
resource "aws_appautoscaling_target" "main" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_id}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.autoscaling_min_capacity
  max_capacity       = var.autoscaling_max_capacity
}

# Scale based on average CPU utilization
resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.project}-${var.name}-cpu"
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

# Scale based on average memory utilization
resource "aws_appautoscaling_policy" "memory" {
  name               = "${var.project}-${var.name}-memory"
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_memory_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

# Scale based on ALB request count per task
resource "aws_appautoscaling_policy" "requests" {
  name               = "${var.project}-${var.name}-requests"
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_requests_per_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = local.alb_request_resource_label
    }
  }
}
