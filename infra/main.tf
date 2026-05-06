module "s3_bucket" {
  source = "../module"

  name        = var.name
  environment = var.environment
  versioning  = true

  enable_lifecycle     = true
  lifecycle_current    = local.lifecycle_by_env[var.environment].current
  lifecycle_noncurrent = local.lifecycle_by_env[var.environment].noncurrent

  # Let the module (and AWS) generate a unique final name by providing a prefix.
  bucket_name   = ""
  bucket_prefix = lower(format("rb-%s-%s-%s-%s-", var.environment, var.name, var.region, formatdate("YYYYMMDDHHmmss", timestamp())))

  tags = { Name = var.name }
}
