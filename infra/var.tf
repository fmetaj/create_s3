variable "region" {
  description = "AWS region where the bucket will be created."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Base bucket name provided by the user. The module appends the creation date and random suffix."
  type        = string
}

variable "environment" {
  description = "Environment tag for this deployment."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the bucket."
  type        = map(string)
  default = {
    Owner   = "artenis"
    Project = "s3-bucket"
  }
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning."
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "S3 encryption type. Supported values are AES256 and aws:kms."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_type)
    error_message = "encryption_type must be either AES256 or aws:kms."
  }
}



variable "lifecycle_rules" {
  description = "Lifecycle rules to apply to the bucket."
  type = list(object({
    id      = string
    enabled = optional(bool, true)
    prefix  = optional(string)
    current_transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration_days = optional(number)
    noncurrent_transitions = optional(list(object({
      noncurrent_days = number
      storage_class   = string
    })), [])
    noncurrent_expiration_days             = optional(number)
    abort_incomplete_multipart_upload_days = optional(number)
  }))
  default = []
}






