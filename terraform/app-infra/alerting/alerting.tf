data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  alb_suffix = replace(var.alb_arn, "/^.+:loadbalancer\\//", "")

  # Keyed map used for for_each — key is workload name to avoid index-based churn.
  workloads = { for w in var.workloads : w.name => merge(w, {
    tg_suffix = replace(w.target_group_arn, "/^.+:/", "")
  }) }
}

# SNS topic for alarm notifications
resource "aws_sns_topic" "alarms" {
  name = "${var.project}-alarms"

  tags = {
    Name = "${var.project}-alarms"
  }
}

# Email subscription — requires manual confirmation after terraform apply
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Allow EventBridge to publish circuit breaker events to this SNS topic
resource "aws_sns_topic_policy" "eventbridge" {
  arn = aws_sns_topic.alarms.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.alarms.arn
      }
    ]
  })
}

# EventBridge rule — fires when the ECS deployment circuit breaker triggers a rollback
resource "aws_cloudwatch_event_rule" "circuit_breaker" {
  for_each = local.workloads

  name        = "${var.project}-${each.key}-circuit-breaker"
  description = "Fires when the ECS deployment circuit breaker rolls back ${each.key}."

  event_pattern = jsonencode({
    source        = ["aws.ecs"]
    "detail-type" = ["ECS Deployment State Change"]
    resources     = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${var.cluster_name}/${each.value.service_name}"]
    detail = {
      eventName = ["SERVICE_DEPLOYMENT_FAILED"]
      reason    = [{ prefix = "ECS deployment circuit breaker" }]
    }
  })

  tags = { Name = "${var.project}-${each.key}-circuit-breaker" }
}

resource "aws_cloudwatch_event_target" "circuit_breaker" {
  for_each = local.workloads

  rule = aws_cloudwatch_event_rule.circuit_breaker[each.key].name
  arn  = aws_sns_topic.alarms.arn
}

# ECS CPU utilization high — one alarm per workload
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  for_each = local.workloads

  alarm_name          = "${var.project}-${each.key}-ecs-cpu-high"
  alarm_description   = "ECS CPU utilization for ${each.key} exceeded 80% for 10 minutes."
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = each.value.service_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = { Name = "${var.project}-${each.key}-ecs-cpu-high" }
}

# ECS memory utilization high — one alarm per workload
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  for_each = local.workloads

  alarm_name          = "${var.project}-${each.key}-ecs-memory-high"
  alarm_description   = "ECS memory utilization for ${each.key} exceeded 80% for 10 minutes."
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = each.value.service_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = { Name = "${var.project}-${each.key}-ecs-memory-high" }
}

# ALB 5XX errors — one alarm per workload target group
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  for_each = local.workloads

  alarm_name          = "${var.project}-${each.key}-alb-5xx"
  alarm_description   = "ALB 5XX errors for ${each.key} exceeded 10 in a 5-minute window."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_suffix
    TargetGroup  = each.value.tg_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = { Name = "${var.project}-${each.key}-alb-5xx" }
}

# ALB unhealthy hosts — one alarm per workload target group
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  for_each = local.workloads

  alarm_name          = "${var.project}-${each.key}-alb-unhealthy-hosts"
  alarm_description   = "One or more ALB targets for ${each.key} are unhealthy."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_suffix
    TargetGroup  = each.value.tg_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = { Name = "${var.project}-${each.key}-alb-unhealthy-hosts" }
}

# ALB target response time p99 — one alarm per workload target group
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  for_each = local.workloads

  alarm_name          = "${var.project}-${each.key}-alb-response-time"
  alarm_description   = "ALB p99 response time for ${each.key} exceeded 2 seconds."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  extended_statistic  = "p99"
  period              = 300
  evaluation_periods  = 2
  threshold           = 2
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_suffix
    TargetGroup  = each.value.tg_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = { Name = "${var.project}-${each.key}-alb-response-time" }
}
