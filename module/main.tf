locals {
  # If the caller provides a full name use it; otherwise prefer a provided prefix
  # so AWS will append a unique suffix. If neither is provided, generate a
  # timestamped prefix here as a sensible default.
  generated_prefix = var.bucket_prefix != "" ? var.bucket_prefix : lower(format("%s-%s-", formatdate("YYYYMMDDHHmmss", timestamp()), var.name))
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name != "" ? var.bucket_name : null
  bucket_prefix = var.bucket_name == "" ? (var.bucket_prefix != "" ? var.bucket_prefix : local.generated_prefix) : null

  lifecycle {
    prevent_destroy = false
  }

  tags = merge({
    Name        = var.name
    Environment = var.environment
  }, var.tags)
}
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning ? "Enabled" : "Suspended"
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.enable_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "simple-lifecycle"
    status = "Enabled"

    # ---- Current object transitions (map key => days) ----
    dynamic "transition" {
      for_each = { for k, v in var.lifecycle_current : k => v if upper(k) != "EXPIRATION" }
      content {
        days          = transition.value
        storage_class = transition.key
      }
    }

    dynamic "expiration" {
      for_each = lookup(var.lifecycle_current, "EXPIRATION", null) != null ? [lookup(var.lifecycle_current, "EXPIRATION", null)] : []
      content {
        days = expiration.value
      }
    }

    # ---- Noncurrent version transitions ----
    dynamic "noncurrent_version_transition" {
      for_each = { for k, v in var.lifecycle_noncurrent : k => v if upper(k) != "EXPIRATION" }
      content {
        noncurrent_days = noncurrent_version_transition.value
        storage_class   = noncurrent_version_transition.key
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = lookup(var.lifecycle_noncurrent, "EXPIRATION", null) != null ? [lookup(var.lifecycle_noncurrent, "EXPIRATION", null)] : []
      content {
        noncurrent_days = noncurrent_version_expiration.value
      }
    }
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "sse_aes" {
  count  = var.enable_encryption && var.encryption_type == "AES256" ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse_kms" {
  count  = var.enable_encryption && var.encryption_type == "aws:kms" ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
  }
}
data "aws_iam_policy_document" "bucket_policy" {
  count = length(var.allowed_role_arns) > 0 ? 1 : 0 #count should be the number of data resources to be created

  statement {
    sid = "AllowRoleAccess"

    principals {
      type        = "AWS"
      identifiers = var.allowed_role_arns
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}
resource "aws_s3_bucket_policy" "this" {
  count  = length(var.allowed_role_arns) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket_policy[0].json
}
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
