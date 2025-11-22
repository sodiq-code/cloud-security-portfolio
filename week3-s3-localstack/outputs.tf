# Define an output variable named "bucket_name" that will be shown after `terraform apply`
output "bucket_name" {

  # Set the output's value to the name of the created S3 bucket resource
  value = aws_s3_bucket.logs.bucket

  description = "The name of the S3 bucket created"
}
