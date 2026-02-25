# Task Role
# Assumed by the application code running inside the container.
resource "aws_iam_role" "task" {
  name = "${var.project}-${var.name}-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project}-${var.name}-task"
  }
}

resource "aws_iam_role_policy" "task_cloudwatch" {
  name = "${var.project}-${var.name}-task-cloudwatch"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/ecs/${var.project}*"
      }
    ]
  })
}
