resource "random_id" "bucket_suffix" {
  byte_length = 3
}

locals {
  normalized_bucket_base = substr(
    trim(replace(lower(var.bucket_name), "/[^a-z0-9-]/", "-"), "-"),
    0,
    47
  )

  final_bucket_name = "${local.normalized_bucket_base}-${random_id.bucket_suffix.hex}"

  has_bucket_policy = true

  policy_statements = [
    {
      sid        = "AllowReadAccess"
      principals = [aws_iam_role.read.arn]

      actions = [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads",
        "s3:GetObjectVersion"
      ]

      resource_type = "both"
    },

    {
      sid        = "AllowWriteAccess"
      principals = [aws_iam_role.write.arn]

      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
        "s3:GetBucketLocation",
        "s3:GetObjectVersion",
        "s3:PutObjectVersionAcl"
      ]

      resource_type = "both"
    },

    {
      sid        = "AllowOperatorAccess"
      principals = [aws_iam_role.operator.arn]

      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketAcl",
        "s3:PutBucketAcl",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:GetBucketLifecycle",
        "s3:PutBucketLifecycle",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning"
      ]

      resource_type = "both"
    }
  ]
}

resource "aws_s3_bucket" "this" {
  bucket = local.final_bucket_name

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
  count                   = var.encryption_type == "aws:kms" ? 1 : 0
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
}

# =========================
# IAM ROLES
# =========================

resource "aws_iam_role" "read" {
  name = "${local.final_bucket_name}-read"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { AWS = "arn:aws:iam::763487052879:root" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "write" {
  name = "${local.final_bucket_name}-write"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { AWS = "arn:aws:iam::763487052879:root" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "operator" {
  name = "${local.final_bucket_name}-operator"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { AWS = "arn:aws:iam::763487052879:root" }
      Action = "sts:AssumeRole"
    }]
  })
}

# =========================
# IAM POLICIES
# =========================

resource "aws_iam_policy" "read" {
  name = "${local.final_bucket_name}-read-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads",
        "s3:GetObjectVersion"
      ]
      Resource = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_policy" "write" {
  name = "${local.final_bucket_name}-write-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
        "s3:GetBucketLocation",
        "s3:GetObjectVersion",
        "s3:PutObjectVersionAcl"
      ]
      Resource = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_policy" "operator" {
  name = "${local.final_bucket_name}-operator-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketAcl",
        "s3:PutBucketAcl",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:GetBucketLifecycle",
        "s3:PutBucketLifecycle",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning"
      ]
      Resource = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/*"
      ]
    }]
  })
}

# =========================
# ATTACHMENTS
# =========================

resource "aws_iam_role_policy_attachment" "read" {
  role       = aws_iam_role.read.name
  policy_arn = aws_iam_policy.read.arn
}

resource "aws_iam_role_policy_attachment" "write" {
  role       = aws_iam_role.write.name
  policy_arn = aws_iam_policy.write.arn
}

resource "aws_iam_role_policy_attachment" "operator" {
  role       = aws_iam_role.operator.name
  policy_arn = aws_iam_policy.operator.arn
}

# =========================
# BUCKET POLICY
# =========================

data "aws_iam_policy_document" "bucket_policy" {
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
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}








