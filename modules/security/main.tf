# modules/security/main.tf

# =============================================================================
# AWS Security Resources
# =============================================================================

# -----------------------------------------------------------------------------
# REMEDIATION: KMS Key for CloudTrail 
# -----------------------------------------------------------------------------
resource "aws_kms_key" "cloudtrail_key" {
  description             = "Customer Managed Key for CloudTrail log encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true  # Security Best Practice: Rotate key automatically
  
  # A basic policy is required for the service to use the key
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
      {
        Sid    = "Allow CloudTrail to encrypt logs"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "kms:GenerateDataKey*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to describe key"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "kms:DescribeKey"
        Resource = "*"
      }
    ]
  })
}

# 1. CloudTrail (The Audit Log)
# Records all API calls and account activity for compliance and forensics
resource "aws_cloudtrail" "main" {
    name                          = "${var.environment}-audit-trail"
    s3_bucket_name                = var.log_bucket_name
    include_global_service_events = true  # Capture IAM, STS, CloudFront events
    is_multi_region_trail         = true  # Monitor all AWS regions
    enable_log_file_validation    = true  # Detect log tampering via digest files

    # use the Customer Managed Key
    kms_key_id = aws_kms_key.cloudtrail_key.arn 
}

# 2. GuardDuty (The Alarm System)
# Threat detection service that monitors for malicious activity
# resource "aws_guardduty_detector" "main" {
#    enable                       = true
#    finding_publishing_frequency = "FIFTEEN_MINUTES"  # How often findings are exported
# }