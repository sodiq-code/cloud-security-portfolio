# -----------------------------------------------------------------------------
# VERSION LOCK (The Fix for LocalStack)
# Pins the AWS provider to version 5.x to avoid "credit specification" errors
# that can occur with LocalStack when using other provider versions.
# -----------------------------------------------------------------------------
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"    
        }
    }
}

# -----------------------------------------------------------------------------
# AWS Provider Configuration for LocalStack
# LocalStack is a local AWS cloud emulator for testing infrastructure locally.
# Uses dummy credentials ("test") since LocalStack doesn't require real AWS keys.
# -----------------------------------------------------------------------------
provider "aws" {
        region                      = "us-east-1"
        access_key                  = "test"          # Dummy credential for LocalStack
        secret_key                  = "test"          # Dummy credential for LocalStack
        skip_credentials_validation = true            # Skip AWS credential validation
        skip_requesting_account_id  = true            # Skip AWS account ID lookup

        # Route all AWS API calls to LocalStack running on localhost:4566
        endpoints {
                ec2 = "http://localhost:4566"
                iam = "http://localhost:4566"
                sts = "http://localhost:4566"
                kms = "http://localhost:4566"
        }
}

# -----------------------------------------------------------------------------
# VPC Module
# Creates the network infrastructure (VPC, subnets, route tables, etc.)
# -----------------------------------------------------------------------------
module "vpc" {
        source      = "../modules/vpc"
        environment = "local"
        region      = "us-east-1"
}

# -----------------------------------------------------------------------------
# IAM Module
# Creates IAM roles and instance profiles for EC2 permissions
# -----------------------------------------------------------------------------
module "iam" {
        source      = "../modules/iam"
        environment = "local"
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

# --------------------------------------------------------------------------
# EC2 Instance (Web Server)
resource "aws_instance" "web" {
    ami                    = "ami-12345678"
    instance_type          = "t2.micro"                        
    subnet_id              = module.vpc.public_subnet_id
    iam_instance_profile   = module.iam.instance_profile_name
    vpc_security_group_ids = [aws_security_group.web_sg.id]

    tags = {
        Name = "Project-A-WebServer"
    }
    metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"  # Forces IMDSv2
  }
  root_block_device {
    encrypted = true
  }
}


