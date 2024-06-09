module "env_files_profile_photos" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.8.2"

  bucket = "lh-${var.env}-profile-photos"
  acl    = "private"

  block_public_acls   = true
  block_public_policy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.lh_env_files_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_kms_key" "profile_photos_files_key" {
  description             = "KMS key used to encrypt bucket objects"
  deletion_window_in_days = 7
}
