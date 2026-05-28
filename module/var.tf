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





