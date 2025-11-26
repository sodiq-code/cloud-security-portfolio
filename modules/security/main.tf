# modules/security/main.tf

# =============================================================================
# AWS Security Resources
# =============================================================================

# 1. CloudTrail (The Audit Log)
# Records all API calls and account activity for compliance and forensics
resource "aws_cloudtrail" "main" {
    name                          = "${var.environment}-audit-trail"
    s3_bucket_name                = var.log_bucket_name
    include_global_service_events = true  # Capture IAM, STS, CloudFront events
    is_multi_region_trail         = true  # Monitor all AWS regions
    enable_log_file_validation    = true  # Detect log tampering via digest files
}

# 2. GuardDuty (The Alarm System)
# Threat detection service that monitors for malicious activity
resource "aws_guardduty_detector" "main" {
    enable                       = true
    finding_publishing_frequency = "FIFTEEN_MINUTES"  # How often findings are exported
}