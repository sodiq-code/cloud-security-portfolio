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
