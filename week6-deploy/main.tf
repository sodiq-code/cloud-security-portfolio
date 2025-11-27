# =============================================================================
# AWS Provider Configuration for LocalStack
# =============================================================================
# This configures Terraform to use LocalStack (local AWS emulator) instead of 
# real AWS services. LocalStack runs on localhost:4566 and allows testing 
# infrastructure without incurring AWS costs.
# =============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Force Version 5 to fix S3 XML errors
    }
  }
}

provider "aws" {
    region                      = "us-east-1"
    access_key                  = "test"        # Dummy credentials for LocalStack
    secret_key                  = "test"        # Dummy credentials for LocalStack
    skip_credentials_validation = true          # Skip AWS credential validation
    skip_requesting_account_id  = true          # Skip AWS account ID lookup

    s3_use_path_style           = true         # Use path-style URLs for S3


    # Route all AWS API calls to LocalStack endpoints
    endpoints {
        ec2        = "http://localhost:4566"
        iam        = "http://localhost:4566"
        sts        = "http://localhost:4566"
        s3         = "http://localhost:4566"
        cloudtrail = "http://localhost:4566"
        guardduty  = "http://localhost:4566"
        kms        = "http://localhost:4566"
    }
}

# =============================================================================
# Module 1: Logging Layer
# =============================================================================
# Creates the centralized S3 bucket for storing security logs.
# This must be created FIRST as other modules depend on it.
# Think of it as "setting up the security camera storage" before the cameras.
# =============================================================================
module "logging" {
    source        = "../modules/logging"
    environment   = "local"
    random_suffix = "12345"              # Ensures unique bucket naming
}

# =============================================================================
# Module 2: Security Layer
# =============================================================================
# Configures security monitoring services (CloudTrail, GuardDuty).
# Depends on logging module - sends all security events to the log bucket.
# Acts as the "security cameras" watching for suspicious activity.
# =============================================================================
module "security" {
    source          = "../modules/security"
    environment     = "local"
    log_bucket_name = module.logging.bucket_name  # Where to store security logs
}

# =============================================================================
# Module 3: Network Layer
# =============================================================================
# Creates the VPC (Virtual Private Cloud) network infrastructure.
# Defines the network boundaries, subnets, and routing for resources.
# This is the "building structure" that contains all other resources.
# =============================================================================
module "vpc" {
    source      = "../modules/vpc"
    environment = "local"
}

# =============================================================================
# Module 4: Identity Layer
# =============================================================================
# Configures IAM roles and policies for access control.
# Follows least-privilege principle - only grants access to specific resources.
# These are the "staff credentials" that define who can access what.
# =============================================================================
module "iam" {
    source            = "../modules/iam"
    environment       = "local"
    # Restricts IAM permissions to ONLY the logging bucket (least-privilege)
    target_bucket_arn = module.logging.bucket_arn
}