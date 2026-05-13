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

variable "kms_key_id" {
  description = "KMS key ID or ARN to use when encryption_type is aws:kms."
  type        = string
  default     = null

  validation {
    condition     = var.encryption_type != "aws:kms" || var.kms_key_id != null
    error_message = "kms_key_id must be provided when encryption_type is aws:kms."
  }

  validation {
    condition     = var.encryption_type == "aws:kms" || var.kms_key_id == null
    error_message = "kms_key_id must be null when encryption_type is AES256."
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

variable "read_role_arns" {
  description = "IAM role ARNs that can list the bucket and read objects."
  type        = list(string)
  default     = []
}

variable "write_role_arns" {
  description = "IAM role ARNs that can upload objects."
  type        = list(string)
  default     = []
}

variable "delete_role_arns" {
  description = "IAM role ARNs that can delete objects."
  type        = list(string)
  default     = []
}

variable "admin_role_arns" {
  description = "IAM role ARNs that should receive full bucket access."
  type        = list(string)
  default     = []
}
