# modules/s3_test/main.tf

# Create an S3 bucket with a fixed, globally-unique name
resource "aws_s3_bucket" "test_bucket" {
    bucket = "afsod-week4-test-bucket-12345"
}

# Block all forms of public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "good_security" {
    bucket = aws_s3_bucket.test_bucket.id

    block_public_acls       = true  # Prevent public ACLs on objects
    block_public_policy     = true  # Prevent bucket policies that allow public access
    ignore_public_acls      = true  # Ignore any public ACLs that might be set
    restrict_public_buckets = true  # Restrict access to only AWS accounts and users
}

# Enforce server-side encryption by default on the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
    
    # References the unique identifier of the S3 bucket resource for use in dependent configurations
    bucket = aws_s3_bucket.test_bucket.id         

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"  # Use S3-managed AES-256 encryption
        }
    }
}