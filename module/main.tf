locals {
  normalized_bucket_base = substr(trim(replace(lower(var.bucket_name), "/[^a-z0-9-]/", "-"), "-"), 0, 47)
  final_bucket_name      = "${local.normalized_bucket_base}-${formatdate("YYYYMMDD-HHMMSS", time_static.created.rfc3339)}"
  has_bucket_policy = (
    length(var.read_role_arns) > 0 ||
    length(var.write_role_arns) > 0 ||
    length(var.delete_role_arns) > 0 ||
    length(var.admin_role_arns) > 0
  )
  policy_statements = [
    {
      sid         = "AllowReadBucketMetadata"
      principals  = var.read_role_arns
      actions     = ["s3:GetBucketLocation", "s3:ListBucket"]
      resource_type = "bucket"
    },
    {
      sid         = "AllowWriteBucketMetadata"
      principals  = var.write_role_arns
      actions     = ["s3:GetBucketLocation", "s3:ListBucketMultipartUploads"]
      resource_type = "bucket"
    },
    {
      sid         = "AllowAdminAccess"
      principals  = var.admin_role_arns
      actions     = ["s3:*"]
      resource_type = "both"
    }
  ]
}

resource "time_static" "created" {}

resource "aws_s3_bucket" "this" {
  bucket = local.final_bucket_name

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(var.tags, {
    Name        = local.final_bucket_name
    Environment = var.environment
  })
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "filter" {
        for_each = try(rule.value.prefix, null) == null ? [1] : []
        content {}
      }

      dynamic "filter" {
        for_each = try(rule.value.prefix, null) == null ? [] : [rule.value.prefix]
        content {
          prefix = filter.value
        }
      }

      dynamic "transition" {
        for_each = try(rule.value.current_transitions, [])
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = try(rule.value.expiration_days, null) == null ? [] : [rule.value.expiration_days]
        content {
          days = expiration.value
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = try(rule.value.noncurrent_transitions, [])
        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = try(rule.value.noncurrent_expiration_days, null) == null ? [] : [rule.value.noncurrent_expiration_days]
        content {
          noncurrent_days = noncurrent_version_expiration.value
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = try(rule.value.abort_incomplete_multipart_upload_days, null) == null ? [] : [rule.value.abort_incomplete_multipart_upload_days]
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aes256" {
  count  = var.encryption_type == "AES256" ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kms" {
  count  = var.encryption_type == "aws:kms" ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  count = local.has_bucket_policy ? 1 : 0

  # Deny any request sent without TLS, regardless of the allow statements below.
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Consolidated allow statements generated from local.policy_statements.
  dynamic "statement" {
    for_each = [for s in local.policy_statements : s if length([for id in s.principals : id if length(trimspace(id)) > 0 && startswith(id, "arn:aws:iam::")]) > 0]
    content {
      sid = statement.value.sid

      principals {
        type = "AWS"
        identifiers = [for id in statement.value.principals : id if length(trimspace(id)) > 0 && startswith(id, "arn:aws:iam::")]
      }

      actions = statement.value.actions

      resources = statement.value.resource_type == "bucket" ? [aws_s3_bucket.this.arn] : (
        statement.value.resource_type == "objects" ? ["${aws_s3_bucket.this.arn}/*"] : [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
      )
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count  = local.has_bucket_policy ? 1 : 0
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
