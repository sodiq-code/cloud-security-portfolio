variable "environment" {
  description = "The deployment environment (e.g., local, dev, prod)"
  type        = string
}

variable "log_bucket_name" {
  description = "The name of the S3 bucket to store security logs"
  type        = string
}