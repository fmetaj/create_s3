module "s3_bucket" {
  source = "../module"

  bucket_name     = var.bucket_name
  environment     = var.environment
  versioning      = var.enable_versioning
  encryption_type = var.encryption_type
  lifecycle_rules = var.lifecycle_rules

  tags = var.tags
}