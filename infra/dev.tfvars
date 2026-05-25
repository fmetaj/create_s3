bucket_name     = "cloud"
encryption_type = "aws:kms"

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
  "arn:aws:iam::763487052879:role/readonly"
]

admin_role_arns = [
  "arn:aws:iam::763487052879:role/adminrole"
]
