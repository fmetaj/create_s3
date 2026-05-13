bucket_name     = "cloud"
environment     = "dev"
encryption_type = "aws:kms"
kms_key_id      = "arn:aws:kms:us-east-1:643327307650:key/16cb9ace-1962-4282-8851-f2f8ef8e4222"

tags = {
  Owner   = "artenis"
  Project = "s3-bucket"
  Team    = "platform"
}

lifecycle_rules = [
  {
    id      = "general-retention"
    enabled = true
    current_transitions = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90
        storage_class = "GLACIER_IR"
      }
    ]
    noncurrent_transitions = [
      {
        noncurrent_days = 30
        storage_class   = "STANDARD_IA"
      }
    ]
    noncurrent_expiration_days             = 180
    abort_incomplete_multipart_upload_days = 7
  }
]

read_role_arns = [
  "arn:aws:iam::069729019498:role/s3-read-role"
]

write_role_arns = [
  "arn:aws:iam::069729019498:role/s3-write-role"
]

delete_role_arns = [
  "arn:aws:iam::069729019498:role/s3-delete-role"
]

admin_role_arns = [
  "arn:aws:iam::069729019498:role/s3-admin-role"
]
