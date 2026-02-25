resource "aws_ecr_repository" "main" {
  name                 = "${var.project}/${var.app_name}"
  image_tag_mutability = "MUTABLE"

  # In production environments this should be false to prevent accidental image loss.
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.app_name}"
  }
}
