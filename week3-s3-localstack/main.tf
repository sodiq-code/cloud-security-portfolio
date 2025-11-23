# Create S3 bucket for logs
resource "aws_s3_bucket" "logs" {      # Define an S3 bucket resource named "logs"
    bucket = var.bucket_name           # Use the bucket name passed in via variable "bucket_name"

    tags = {                           # Add metadata tags to the bucket
        Name = "week3-tf-s3"           # Tag: human-readable name for the bucket
        Env  = "dev"                   # Tag: environment indicator (development)
    }
}

# Set bucket ACL to private
resource "aws_s3_bucket_acl" "logs_acl" {  # Define a bucket ACL resource named "logs_acl"
    bucket = aws_s3_bucket.logs.id         # Apply ACL to the "logs" bucket by its ID
    acl    = "private"                     # Set access control list so bucket is fully private
}

resource "aws_s3_bucket_public_access_block" "logs_public_access_block" {
  # Targets the S3 bucket defined in this file
  bucket = aws_s3_bucket.logs.id 

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 1. Define the Customer Managed Key (CMK)
resource "aws_kms_key" "logs_key" {
  description             = "KMS Key for logs bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

# 2. Configure the S3 bucket to use the CMK
resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encryption" {
    bucket = aws_s3_bucket.logs.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm     = "aws:kms"
            kms_master_key_id = aws_kms_key.logs_key.arn 
        }
    }
}
