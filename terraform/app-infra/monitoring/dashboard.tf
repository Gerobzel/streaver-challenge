data "aws_region" "current" {}

locals {
  alb_suffix = replace(var.alb_arn, "/^.+:loadbalancer\\//", "")

  # Pre-compute per-workload values used in dashboard widgets
  workloads = [for w in var.workloads : {
    name      = w.name
    service   = w.service_name
    tg_suffix = replace(w.target_group_arn, "/^.+:/", "")
    log_group = w.log_group_name
  }]
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS CPU Utilization"
          region = data.aws_region.current.name
          stat   = "Average"
          period = 300
          # One line per workload — add a workload to var.workloads to get a new line automatically.
          metrics = [for w in local.workloads :
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", w.service, { label = w.name }]
          ]
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS Memory Utilization"
          region = data.aws_region.current.name
          stat   = "Average"
          period = 300
          # One line per workload — add a workload to var.workloads to get a new line automatically.
          metrics = [for w in local.workloads :
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", w.service, { label = w.name }]
          ]
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ALB Request Count"
          region = data.aws_region.current.name
          stat   = "Sum"
          period = 300
          # One line per workload — add a workload to var.workloads to get a new line automatically.
          metrics = [for w in local.workloads :
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_suffix, "TargetGroup", w.tg_suffix, { label = w.name }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ALB 5XX Errors"
          region = data.aws_region.current.name
          stat   = "Sum"
          period = 300
          # One line per workload — add a workload to var.workloads to get a new line automatically.
          metrics = [for w in local.workloads :
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffix, "TargetGroup", w.tg_suffix, { label = w.name }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ALB Target Response Time (p99)"
          region = data.aws_region.current.name
          stat   = "p99"
          period = 300
          # One line per workload — add a workload to var.workloads to get a new line automatically.
          metrics = [for w in local.workloads :
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_suffix, "TargetGroup", w.tg_suffix, { label = w.name }]
          ]
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          title  = "Application Logs"
          region = data.aws_region.current.name
          # All workload log groups are queried together — add a workload to var.workloads to include its logs automatically.
          query = "SOURCE ${join(", ", [for w in local.workloads : "'${w.log_group}'"])} | fields @timestamp, @log, @message | sort @timestamp desc | limit 50"
          view  = "table"
        }
      }
    ]
  })
}
