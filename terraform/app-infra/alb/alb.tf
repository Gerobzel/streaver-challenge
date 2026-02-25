# ACM Certificate (importing the self-signed cert generated in ssl-certificate.tf)
resource "aws_acm_certificate" "self_signed" {
  private_key      = tls_private_key.self_signed.private_key_pem
  certificate_body = tls_self_signed_cert.self_signed.cert_pem
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name   = "${var.project}-alb"
  vpc_id = var.public_vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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
    Name = "${var.project}-alb"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project}-alb"
  }
}

# Target Group — stable variant
resource "aws_lb_target_group" "stable" {
  name        = "${var.project}-stable"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.private_vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project}-stable"
  }
}

# Target Group — canary variant
resource "aws_lb_target_group" "canary" {
  name        = "${var.project}-canary"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.private_vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project}-canary"
  }
}

# HTTPS listener — SSL offload, weighted forward to stable/canary target groups
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.self_signed.arn

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.stable.arn
        weight = var.weight_stable
      }

      target_group {
        arn    = aws_lb_target_group.canary.arn
        weight = var.weight_canary
      }
    }
  }
}
