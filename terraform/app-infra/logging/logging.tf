# S3 bucket — receives all ECS logs via Firehose, 1-year retention
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project}-logs"

  # In production environments this should be false to prevent accidental data loss.
  force_destroy = true

  tags = {
    Name = "${var.project}-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-after-1-year"
    status = "Enabled"

    expiration {
      days = 365
    }
  }
}

# One Firehose delivery stream per log group — each writes to a scoped S3 prefix.
# CloudWatch Logs → Firehose → S3 runs in parallel with 30-day CW retention.
resource "aws_kinesis_firehose_delivery_stream" "logs" {
  for_each    = var.log_groups
  name        = "${var.project}-${each.key}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = aws_s3_bucket.logs.arn
    prefix              = "${each.key}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/${each.key}/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    compression_format  = "GZIP"
    buffering_interval  = 300
    buffering_size      = 5
  }

  tags = {
    Name = "${var.project}-${each.key}"
  }
}

# Subscription filter — pipes CloudWatch log events into Firehose in near real-time
resource "aws_cloudwatch_log_subscription_filter" "logs" {
  for_each = var.log_groups

  name            = "${var.project}-${each.key}-to-s3"
  log_group_name  = each.value
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.logs[each.key].arn
  role_arn        = aws_iam_role.cwl_to_firehose.arn
}
