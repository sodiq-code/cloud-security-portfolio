# week8-ha-deploy/main.tf
# This Terraform configuration deploys a High-Availability (HA) web application
# using AWS Application Load Balancer (ALB) and Auto Scaling Group (ASG).

# =============================================================================
# TERRAFORM SETTINGS
# =============================================================================
terraform {
    required_version = ">= 1.5.0"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.67"
        }
    }
}

# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================
# Configures AWS provider to use LocalStack (local AWS emulator) for testing.
# In production, remove the fake credentials and endpoint overrides.
provider "aws" {
    region                      = "us-east-2"
    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    # Allow STS to return the (fake) account ID so S3 Control APIs have a valid value
    skip_requesting_account_id  = false
    s3_use_path_style           = true

    endpoints {
        ec2         = "http://localhost:4566"
        s3          = "http://localhost:4566"
        s3control   = "http://localhost:4566"
        iam         = "http://localhost:4566"
        sts         = "http://localhost:4566"
        cloudtrail  = "http://localhost:4566"
        cloudwatch  = "http://localhost:4566"
        guardduty   = "http://localhost:4566"
        kms         = "http://localhost:4566"
        elb         = "http://localhost:4566"
        elbv2       = "http://localhost:4566" # ALB API endpoint
        wafv2       = "http://localhost:4566"
        autoscaling = "http://localhost:4566"
    }
}

# =============================================================================
# LAYER 1: LOGGING (Audit Trail & Compliance)
# =============================================================================
# Creates S3 bucket for storing logs. Essential for security audits,
# troubleshooting, and compliance requirements (e.g., SOC2, HIPAA).
module "logging" {
    source        = "../modules/logging"
    environment   = "ha-prod"
    random_suffix = "99999"
}

# =============================================================================
# LAYER 2: SECURITY MONITORING (Threat Detection)
# =============================================================================
# Enables CloudTrail (API activity logging) and GuardDuty (threat detection).
# Logs are stored in the bucket created above.
module "security" {
    source          = "../modules/security"
    environment     = "ha-prod"
    log_bucket_name = module.logging.bucket_name
}

# =============================================================================
# LAYER 3: NETWORKING (VPC Infrastructure)
# =============================================================================
# Creates the Virtual Private Cloud with public/private subnets.
# This isolates our infrastructure from other AWS accounts.
module "vpc" {
    source      = "../modules/vpc"
    environment = "ha-prod"
}

# =============================================================================
# LAYER 4: IDENTITY & ACCESS MANAGEMENT (Permissions)
# =============================================================================
# Creates IAM role and instance profile for EC2 instances.
# Follows least-privilege principle - servers only get permissions they need.
module "iam" {
    source            = "../modules/iam"
    environment       = "ha-prod"
    target_bucket_arn = module.logging.bucket_arn
}

# =============================================================================
# LAUNCH TEMPLATE (Server Blueprint)
# =============================================================================
# Defines HOW each server should be created. Think of it as a "recipe" that
# the Auto Scaling Group uses to spin up identical servers on demand.
# Key benefit: Consistency - every server is configured exactly the same.
resource "aws_launch_template" "app" {
    name_prefix   = "ha-app-"
    image_id      = "ami-02d1e544b84bf7502"  # Amazon Linux 2 AMI for us-east-2 (update as needed)
    instance_type = "t2.micro"      # Server size (CPU, RAM)

    # Attach IAM role so instances can access AWS services securely
    # (e.g., read from S3, write to CloudWatch) without hardcoded credentials
    iam_instance_profile {
        name = module.iam.instance_profile_name
    }

    # Apply firewall rules - instances only accept traffic from ALB
    # Security: Only allow traffic from ALB security group
    vpc_security_group_ids = [aws_security_group.instance_sg.id]

    # Require IMDSv2 to prevent SSRF attacks on instance metadata
    metadata_options {
        http_tokens   = "required"
        http_endpoint = "enabled"
    }

    # Tag all instances for easy identification in AWS Console
    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "HA-WebServer-Worker"
        }
    }
}

# =============================================================================
# SECURITY GROUP: LOAD BALANCER (Public-Facing Firewall)
# =============================================================================
# Firewall rules for the ALB - the ONLY component exposed to the internet.
# Ingress: Allow HTTP (port 80) from anywhere (0.0.0.0/0 = all IPs)
# Egress: Allow all outbound traffic to reach backend servers
resource "aws_security_group" "alb_sg" {
    name        = "ha-alb-sg"
    description = "Allow Internet to ALB"
    vpc_id      = module.vpc.vpc_id

    # Inbound: Accept HTTP requests from the entire internet
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Outbound: Allow ALB to forward requests to backend instances
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"          # -1 = all protocols
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# =============================================================================
# SECURITY GROUP: EC2 INSTANCES (Private Firewall)
# =============================================================================
# Firewall rules for backend servers - NOT directly accessible from internet.
# CRITICAL SECURITY PATTERN: Only the ALB can reach these servers.
# This prevents direct attacks on application servers.
resource "aws_security_group" "instance_sg" {
    name        = "ha-instance-sg"
    description = "Allow traffic ONLY from ALB"
    vpc_id      = module.vpc.vpc_id

    # Inbound: ONLY accept traffic from the ALB security group
    # This is the "magic link" - uses security group ID instead of IP ranges
    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.alb_sg.id]
    }

    # Outbound: Allow instances to reach internet (for updates, API calls, etc.)
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# =============================================================================
# WAF (Web Application Firewall) - Layer 7 Defense
# =============================================================================
# PURPOSE: Protects against common web attacks like SQL Injection (SQLi) and
# Cross-Site Scripting (XSS) by inspecting HTTP/HTTPS traffic at the ALB.
#
# WHY IT MATTERS:
# - Security groups only filter by IP/port (Layer 3-4)
# - WAF inspects actual request content (Layer 7) - headers, body, query strings
# - Blocks malicious payloads BEFORE they reach your application
# =============================================================================

resource "aws_wafv2_web_acl" "main" {
    name        = "ha-prod-waf"
    description = "Protects ALB from SQLi, XSS, and common web exploits"
    scope       = "REGIONAL"  # REGIONAL = ALB/API Gateway, CLOUDFRONT = CDN

    # Default behavior: Allow traffic that doesn't match any blocking rules
    # This is a "blocklist" approach - only explicitly bad traffic is stopped
    default_action {
        allow {}
    }

    # ---------------------------------------------------------------------------
    # RULE 1: AWS Managed Common Rule Set
    # ---------------------------------------------------------------------------
    # Pre-built rules maintained by AWS security team. Includes protection for:
    # - SQL Injection (SQLi) - Malicious database queries
    # - Cross-Site Scripting (XSS) - Script injection attacks
    # - Local File Inclusion (LFI) - Unauthorized file access attempts
    # - Path Traversal - Attempts to access ../../../etc/passwd
    #
    # WHY MANAGED RULES: AWS continuously updates these rules as new attack
    # patterns emerge - you get protection without manual rule maintenance.
    # ---------------------------------------------------------------------------
    rule {
        name     = "AWSManagedRulesCommonRuleSet"
        priority = 1  # Lower number = evaluated first

        # Use the rule group's default actions (block/count as defined by AWS)
        override_action {
            none {}
        }

        statement {
            managed_rule_group_statement {
                name        = "AWSManagedRulesCommonRuleSet"
                vendor_name = "AWS"
            }
        }

        # CloudWatch metrics for monitoring blocked requests
        # Check these metrics to see attack attempts against your application
        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "CommonRuleSetMetrics"
            sampled_requests_enabled   = true  # Store sample requests for analysis
        }
    }

    # Global visibility config for the entire Web ACL
    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "ha-prod-waf-metrics"
        sampled_requests_enabled   = true
    }

    tags = {
        Name        = "HA-Prod-WAF"
        Environment = "ha-prod"
    }
}

# =============================================================================
# WAF-to-ALB Association
# =============================================================================
# CRITICAL: This resource "attaches" the WAF to the ALB.
# Without this association, the WAF rules exist but do nothing!
#
# TRAFFIC FLOW AFTER ASSOCIATION:
# Internet → ALB → [WAF Inspection] → If clean → Target Group → EC2 Instances
#                                   → If malicious → 403 Blocked
# =============================================================================
resource "aws_wafv2_web_acl_association" "main" {
    resource_arn = aws_lb.main.arn       # The ALB to protect
    web_acl_arn  = aws_wafv2_web_acl.main.arn  # The WAF rules to apply
}

# =============================================================================
# APPLICATION LOAD BALANCER (Traffic Distributor)
# =============================================================================
# The single entry point for all user traffic. Distributes requests across
# multiple healthy backend servers. Benefits:
# - High Availability: If one server dies, traffic goes to others
# - Scalability: Add more servers without changing DNS
# - Security: Hides backend servers from direct internet access
resource "aws_lb" "main" {
    name               = "ha-load-balancer"
    internal           = false                          # false = internet-facing
    load_balancer_type = "application"                  # Layer 7 (HTTP/HTTPS)
    drop_invalid_header_fields = true  # Prevent HTTP header injection attacks
    security_groups    = [aws_security_group.alb_sg.id]
    subnets            = [module.vpc.public_subnet_id]
    #Note:  Using 2 public subnets across different AZs for high availability in Production
}

# =============================================================================
# TARGET GROUP (Backend Server Registry)
# =============================================================================
# A logical grouping of backend servers. The ALB uses this to know
# WHERE to send traffic. Includes health checks to detect failed servers.
resource "aws_lb_target_group" "app" {
    name     = "ha-target-group"
    port     = 80                  # Port where app listens
    protocol = "HTTP"
    vpc_id   = module.vpc.vpc_id
    # Health checks are configured by default (GET / every 30s)
}

# =============================================================================
# ALB LISTENER (Request Router)
# =============================================================================
# Defines what the ALB does when it receives traffic on a specific port.
# This listener: "When traffic arrives on port 80, forward it to the target group"
resource "aws_lb_listener" "front_end" {
    load_balancer_arn = aws_lb.main.arn
    port              = "80"
    protocol          = "HTTP"
    # NOTE: Production should use HTTPS (port 443) with SSL certificate
    # TODO: For production, configure an HTTPS listener with a valid SSL certificate to ensure secure communication.

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.app.arn
    }
}

# =============================================================================
# AUTO SCALING GROUP (Self-Healing Infrastructure)
# =============================================================================
# The "brain" that maintains desired number of healthy servers.
# Key behaviors:
# - Replaces failed instances automatically (self-healing)
# - Scales out when demand increases (if max_size > desired_capacity)
# - Scales in when demand decreases (cost optimization)
# - Registers new instances with the ALB target group automatically
resource "aws_autoscaling_group" "app" {
    name                = "ha-asg"
    vpc_zone_identifier = [module.vpc.public_subnet_id]  # Subnets available for the ASG
    target_group_arns   = [aws_lb_target_group.app.arn]  # Auto-register with ALB

    # Use the launch template to create instances
    launch_template {
        id      = aws_launch_template.app.id
        version = "$Latest"  # Always use newest template version
    }

    # Capacity settings:
    min_size         = 2  # Never go below 2 (high availability)
    max_size         = 3  # Cap at 3 to control costs
    desired_capacity = 2  # Start with 2 instances
}