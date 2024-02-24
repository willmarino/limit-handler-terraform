module "env_files" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.8.2"

  bucket = "lh-${var.env}-env-files"
  acl    = "private"

  block_public_acls   = true
  block_public_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.lh_env_files_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_kms_key" "lh_env_files_key" {
  description             = "KMS key is used to encrypt bucket objects"
  deletion_window_in_days = 7
}
