variable "environment" {
  description = "The deployment environment"
  type        = string
}

variable "target_bucket_arn" {
  description = "The ARN of the S3 bucket the IAM role can access"
  type        = string
  default     = "*" # Optional default if you want to allow broad access initially
}