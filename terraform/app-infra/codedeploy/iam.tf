resource "aws_iam_role" "codedeploy" {
  name = "${var.project}-codedeploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "codedeploy.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project}-codedeploy"
  }
}

# Grants CodeDeploy everything it needs: create/update ECS task sets, modify ALB
# listener rules, register/deregister targets, and read CloudWatch alarms.
resource "aws_iam_role_policy_attachment" "codedeploy_ecs" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}
