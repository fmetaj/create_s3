module "s3_bucket" {
  source = "../module"

  bucket_name     = var.bucket_name
  environment     = var.environment
  versioning      = var.enable_versioning
  encryption_type = var.encryption_type
  kms_key_id      = var.kms_key_id
  lifecycle_rules = var.lifecycle_rules

  read_role_arns   = var.read_role_arns
  write_role_arns  = var.write_role_arns
  delete_role_arns = var.delete_role_arns
  admin_role_arns  = var.admin_role_arns

  tags = var.tags
}
