# week3-s3-localstack/main.tf

resource "aws_s3_bucket" "logs" {
    bucket = var.bucket_name

    # Basic tags for identification and environment tracking
    tags = {
        Name = "week3-tf-s3"
        Env  = "dev"
    }
}

resource "aws_s3_bucket_acl" "logs_acl" {
    bucket = aws_s3_bucket.logs.id
    acl    = "private" # Ensure bucket is not publicly readable
}

# --- SECURITY FIXES BELOW ---

# 1. Block all forms of public access to the bucket
resource "aws_s3_bucket_public_access_block" "logs_public_access_block" {
    bucket = aws_s3_bucket.logs.id

    block_public_acls       = true  # Reject public ACLs
    block_public_policy     = true  # Reject public bucket policies
    ignore_public_acls      = true  # Ignore any public ACLs if set
    restrict_public_buckets = true  # Restrict public bucket access via policies
}

# 2. Create a KMS CMK to encrypt S3 objects
resource "aws_kms_key" "logs_key" {
    description             = "KMS Key for logs bucket encryption"
    deletion_window_in_days = 10    # Waiting period before key deletion
    enable_key_rotation     = true  # Annual key rotation
}

# 3. Enforce default server-side encryption using the KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encryption" {
    bucket = aws_s3_bucket.logs.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm     = "aws:kms"                # Use KMS-based encryption
            kms_master_key_id = aws_kms_key.logs_key.arn # Reference the CMK above
        }
    }
}