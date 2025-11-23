# week3-s3-localstack/main.tf

resource "aws_s3_bucket" "logs" {
    bucket = var.bucket_name
    tags = {
        Name = "week3-tf-s3"
        Env  = "dev"
    }
}

resource "aws_s3_bucket_acl" "logs_acl" {
    bucket = aws_s3_bucket.logs.id
    acl    = "private"
}

# --- SECURITY FIXES BELOW ---

# 1. Block Public Access
resource "aws_s3_bucket_public_access_block" "logs_public_access_block" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. KMS Key for Encryption
resource "aws_kms_key" "logs_key" {
  description             = "KMS Key for logs bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

# 3. Apply KMS Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encryption" {
    bucket = aws_s3_bucket.logs.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm     = "aws:kms"
            kms_master_key_id = aws_kms_key.logs_key.arn
        }
    }
}