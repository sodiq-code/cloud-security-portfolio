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

# -----------------------------------------------------------------------------
# Security Group (Firewall Rules)
# Defines inbound/outbound traffic rules for the web server.
# - Allows inbound HTTP (port 80) from any IP address
# - Allows all outbound traffic to HTTPS (port 443) (required for updates, external APIs, etc.)
# -----------------------------------------------------------------------------
resource "aws_security_group" "web_sg" {
        name        = "web-server-sg"
        description = "Allow HTTP traffic"
        vpc_id      = module.vpc.vpc_id       # Attach to VPC created by module

        # Inbound rule: Allow HTTP traffic from anywhere
        ingress {
                from_port   = 80
                to_port     = 80
                protocol    = "tcp"
                cidr_blocks = ["0.0.0.0/0"]        # WARNING: Open to all IPs (use cautiously)
        }

        # Outbound rule: Restrict Egress Traffic (Security Best Practice)
        # Instead of allowing unrestricted outbound access (0.0.0.0/0), this rule
        # limits egress to only the VPC CIDR block (10.0.0.0/16).

        egress {
                description = "Restrict egress to VPC only - blocks internet access"
                from_port   = 0                   # All ports
                to_port     = 0                   # All ports
                protocol    = "-1"                # All protocols (-1 = any)
                cidr_blocks = ["10.0.0.0/16"]     # VPC internal traffic only
        }
}

# =============================================================================
# Compute Resource (EC2 Instance)
# =============================================================================
# The actual Web Server instance.
# - Placed in the Public Subnet (from VPC module)
# - Protected by the Security Group defined above
# - Identity provided by the IAM Instance Profile (from IAM module)
# =============================================================================
# resource "aws_instance" "web" {
#   ami           = "ami-12345678"  # LocalStack dummy AMI
#   instance_type = "t2.micro"

#   # Network Placement
#   subnet_id              = module.vpc.public_subnet_id
#   vpc_security_group_ids = [aws_security_group.web_sg.id]

#   # Identity (The IAM Role)
#   iam_instance_profile = module.iam.instance_profile_name

#   # Hardening: Enforce IMDSv2 (Token required) to prevent SSRF
#   metadata_options {
#     http_tokens   = "required"
#     http_endpoint = "enabled"
#   }

#   # Hardening: Encrypt Root Volume
#   root_block_device {
#     encrypted = true
#   }

#   # Timeout setting to prevent "Hanging" issues in LocalStack
#   timeouts {
#     create = "1m"
#   }

#   tags = {
#     Name = "Project-A-Secure-Web-Server"
#   }
# }