# modules/logging/main.tf
# This module creates a secure S3 bucket for storing CloudTrail logs

# -----------------------------------------------------------------------------
# REQUIRED RESOURCE: KMS Key for S3 Bucket Encryption
# -----------------------------------------------------------------------------
resource "aws_kms_key" "cloudtrail_kms_key" {
  description             = "KMS key for CloudTrail logging bucket"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  # The policy ensures the root account can manage the key and CloudTrail can use it.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # Grants CloudTrail permission to perform encryption operations using this key.
      {
        Sid    = "Allow CloudTrail to encrypt logs"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "kms:GenerateDataKey*"
        Resource = "*"
      }
    ]
  })
}

# 1. The Log Bucket
# Creates the primary S3 bucket where all security logs will be stored
# Uses environment prefix and random suffix to ensure unique bucket names
resource "aws_s3_bucket" "logs" {
    bucket        = "${var.environment}-security-logs-${var.random_suffix}"
    force_destroy = true # WARNING: Lab only - allows bucket deletion with contents
}

# 2. Block All Public Access (Security Requirement)
# Prevents any public exposure of log data - critical for compliance
# All four settings must be true for complete public access prevention
resource "aws_s3_bucket_public_access_block" "logs" {
    bucket = aws_s3_bucket.logs.id

    block_public_acls       = true # Reject PUT requests with public ACLs
    block_public_policy     = true # Reject bucket policies that grant public access
    ignore_public_acls      = true # Ignore any existing public ACLs on objects
    restrict_public_buckets = true # Restrict cross-account access to bucket
}

# 3. Encrypt the Logs (Compliance Requirement)
# Enables server-side encryption for all objects stored in the bucket
# Using AWS KMS with customer-managed keys for enhanced control over encryption
# Benefits: Key rotation, access policies, audit trails via CloudTrail
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
    bucket = aws_s3_bucket.logs.id
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "aws:kms" # Customer-managed keys for greater control
            kms_master_key_id = aws_kms_key.cloudtrail_kms_key.arn # Specify your KMS key ARN
        }
    }
}

# 4. Bucket Policy (Allow CloudTrail to write here)
# Grants CloudTrail service the minimum permissions needed to deliver logs
resource "aws_s3_bucket_policy" "allow_cloudtrail" {
    bucket = aws_s3_bucket.logs.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                # Allows CloudTrail to verify bucket ownership before writing
                Sid       = "AWSCloudTrailAclCheck"
                Effect    = "Allow"
                Principal = { Service = "cloudtrail.amazonaws.com" }
                Action    = "s3:GetBucketAcl"
                Resource  = aws_s3_bucket.logs.arn
            },
            {
                # Allows CloudTrail to write log files to the bucket
                # Condition ensures bucket owner maintains full control of delivered logs
                Sid       = "AWSCloudTrailWrite"
                Effect    = "Allow"
                Principal = { Service = "cloudtrail.amazonaws.com" }
                Action    = "s3:PutObject"
                Resource  = "${aws_s3_bucket.logs.arn}/*"
                Condition = {
                    StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
                }
            }
        ]
    })
}