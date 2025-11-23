# modules/s3_test/main.tf

resource "aws_s3_bucket" "test_bucket" {

  # We use a random suffix to make it unique
  bucket = "afsod-week4-test-bucket-12345"
}

# ⚠️ SECURITY RISK: This configuration allows Public Access!
# The scanner should detect this as a HIGH severity issue.

resource "aws_s3_bucket_public_access_block" "bad_security" {
  bucket = aws_s3_bucket.test_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ⚠️ SECURITY RISK: No Encryption configured!