locals {
  normalized_bucket_base = substr(trim(replace(lower(var.bucket_name), "/[^a-z0-9-]/", "-"), "-"), 0, 47)
  final_bucket_name = "${local.normalized_bucket_base}-${formatdate("YYYYMMDDhhmmss", time_static.created.rfc3339)}"
  has_bucket_policy = true

policy_statements = [
  {
    sid           = "AllowReadAccess"
    principals    = [aws_iam_role.read.arn]
    actions       = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resource_type = "both"
  },

  {
    sid           = "AllowOfficerAccess"
    principals    = [aws_iam_role.officer.arn]
    actions       = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resource_type = "both"
  },

  {
    sid           = "AllowOperatorAccess"
    principals    = [aws_iam_role.operator.arn]
    actions       = [
      "s3:*"
    ]
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
resource "aws_kms_key" "this" {
  count = var.encryption_type == "aws:kms" ? 1 : 0

  description             = "KMS key for S3 bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true
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
      kms_master_key_id = aws_kms_key.this[0].arn
    }
  }
}# =========================
# READ ROLE
# =========================

resource "aws_iam_role" "read" {
  name = "${local.final_bucket_name}-read"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::763487052879:root"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "read" {
  name = "${local.final_bucket_name}-read-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]

        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "read" {
  role       = aws_iam_role.read.name
  policy_arn = aws_iam_policy.read.arn
}

# =========================
# OFFICER ROLE
# =========================

resource "aws_iam_role" "officer" {
  name = "${local.final_bucket_name}-officer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::763487052879:root"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "officer" {
  name = "${local.final_bucket_name}-officer-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]

        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "officer" {
  role       = aws_iam_role.officer.name
  policy_arn = aws_iam_policy.officer.arn
}

# =========================
# OPERATOR ROLE
# =========================

resource "aws_iam_role" "operator" {
  name = "${local.final_bucket_name}-operator"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::763487052879:root"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "operator" {
  name = "${local.final_bucket_name}-operator-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:*"
        ]

        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "operator" {
  role       = aws_iam_role.operator.name
  policy_arn = aws_iam_policy.operator.arn
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
