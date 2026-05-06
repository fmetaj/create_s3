variable "name" {
  description = "Logical name of the bucket (application or purpose)"
  type        = string
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to the bucket"
  type        = map(string)
  default     = {}
}

variable "bucket_name" {
  description = "Full S3 bucket name"
  type        = string
}
variable "bucket_prefix" {
  description = "Prefix for provider-generated bucket names (provider will append a unique suffix)."
  type        = string
  default     = ""
}
variable "versioning" {
  description = "Enable S3 versioning"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable server-side encryption"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type: AES256 or aws:kms"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_type)
    error_message = "encryption_type must be AES256 or aws:kms"
  }
}

variable "kms_key_id" {
  description = "KMS key ID or ARN (required if aws:kms is used)"
  type        = string
  default     = null
}

variable "allowed_role_arns" {
  description = "IAM role ARNs allowed to access the bucket"
  type        = list(string)
  default     = []
}

variable "enable_lifecycle" {
  description = "Enable lifecycle rules"
  type        = bool
  default     = true
}

variable "lifecycle_current" {
  description = "Lifecycle rules for current object versions"
  type        = map(number)
}

variable "lifecycle_noncurrent" {
  description = "Lifecycle rules for noncurrent (versioned) objects"
  type        = map(number)
}