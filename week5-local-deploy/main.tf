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
# - Allows all outbound traffic (required for updates, external APIs, etc.)
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

        # Outbound rule: Allow all outbound traffic
        egress {
                from_port   = 0
                to_port     = 0
                protocol    = "-1"                 # "-1" means all protocols
                cidr_blocks = ["0.0.0.0/0"]
        }
}

# -----------------------------------------------------------------------------
# EC2 Instance (Web Server)
# Creates a t2.micro instance in the public subnet with:
# - IAM instance profile for AWS service permissions
# - Security group for network access control
# - LocalStack-compatible timeouts and lifecycle settings
# -----------------------------------------------------------------------------
resource "aws_instance" "web" {
        ami                    = "ami-12345678"                    # Placeholder AMI ID (use valid ID in production)
        instance_type          = "t2.micro"                        # Free-tier eligible instance size
        subnet_id              = module.vpc.public_subnet_id       # Deploy in public subnet for internet access
        iam_instance_profile   = module.iam.instance_profile_name  # Attach IAM role for AWS API access
        vpc_security_group_ids = [aws_security_group.web_sg.id]    # Apply firewall rules

        # Explicit credit specification for T2 instances to avoid LocalStack issues
        # LocalStack may not fully support default credit specification behavior
        credit_specification {
                cpu_credits = "standard"
        }

        tags = {
                Name = "Project-A-WebServer"
        }

        # Timeouts to prevent hanging during LocalStack deployments
        # LocalStack EC2 may not return expected instance status, causing indefinite waits
        timeouts {
                create = "5m"
                update = "5m"
                delete = "5m"
        }

        # Lifecycle settings for LocalStack compatibility
        # create_before_destroy ensures smoother resource replacement
        lifecycle {
                create_before_destroy = true
        }
}