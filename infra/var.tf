#Variable folder so everything can be used in the future

#region vaiable
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

#tag for the enviroment (optional), have been updated to use map
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)

  default = {
    Environment = "dev"
    Owner       = "artenis"
    Project     = "s3-bucket"
  }
}
#variable for the lifecycle(default is its turned off)
variable "enable_lifecycle" {
  description = "Enable lifecycle rule for old object versions"
  type        = bool
  default     = false
}
#variable for the days of the lifecycle
variable "noncurrent_days" {
  description = "Days before old object versions are deleted"
  type        = number
  default     = 30
}

#optional custom bucket name
#leave empty ("") to use auto-generated name
variable "bucket_name" {
  description = "Custom S3 bucket name (optional). If empty, a random name will be used."
  type        = string
  default     = ""
}

#variable for making versioning optional 
variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}


#decides encryption type, default is AES256
variable "encryption_type" {
  description = "S3 encryption type. Use AES256 for SSE-S3 or aws:kms for SSE-KMS."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_type)
    error_message = "encryption_type must be either AES256 or aws:kms."
  }
}
#different storage options based on the age of the docs each type of transition is now optional, each has its own variable


variable "transition_to_ia_days" {
  description = "Days before moving objects to Standard-IA"
  type        = number
  default     = 30
}

variable "transition_to_glacier_days" {
  description = "Days before moving objects to Glacier Instant Retrieval"
  type        = number
  default     = 90
}

variable "transition_to_deep_archive_days" {
  description = "Days before moving objects to Deep Archive"
  type        = number
  default     = 180
}
variable "enable_transition_to_ia" {
  type    = bool
  default = true
}

variable "enable_transition_to_glacier" {
  type    = bool
  default = true
}

variable "enable_transition_to_deep_archive" {
  type    = bool
  default = true
}

#variables for bucket policies
variable "read_principals" {
  type    = list(string)
  default = []
}

variable "write_principals" {
  type    = list(string)
  default = []
}

variable "delete_principals" {
  type    = list(string)
  default = []
}


#variable for admin principals needed for the other principals
variable "admin_principals" {
  type = list(string)
  default = [
    "arn:aws:iam::069729019498:root"
  ]
}