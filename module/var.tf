variable "bucket_name" {
  description = "Base bucket name supplied by the caller. The module appends the creation date and a random suffix."
  type        = string

  validation {
    condition     = length(trim(replace(lower(var.bucket_name), "/[^a-z0-9-]/", "-"), "-")) > 0
    error_message = "bucket_name must contain at least one letter or number."
  }
}

variable "environment" {
  description = "Environment tag for the bucket."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to the bucket."
  type        = map(string)
  default     = {}
}

variable "versioning" {
  description = "Enable S3 versioning."
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type for the bucket. Supported values are AES256 and aws:kms."
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
  description = "IAM role ARNs that can list the bucket and read objects. When using aws:kms, these roles also need KMS decrypt access on the referenced key."
  type        = list(string)
  default     = []
}

variable "write_role_arns" {
  description = "IAM role ARNs that can upload objects. When using aws:kms, these roles also need KMS encrypt and data-key permissions on the referenced key."
  type        = list(string)
  default     = []
}

variable "delete_role_arns" {
  description = "IAM role ARNs that can delete objects."
  type        = list(string)
  default     = []
}

variable "admin_role_arns" {
  description = "IAM role ARNs that should receive full bucket access. When using aws:kms, these roles also need matching KMS administrative or usage permissions on the referenced key."
  type        = list(string)
  default     = []
}
