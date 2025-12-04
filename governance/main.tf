# governance/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"  # Pinning to stable version for LocalStack
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    organizations = "http://localhost:4566"
    sts           = "http://localhost:4566"
  }
}

# 1. Create the Organization (The Root)
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com"
  ]
  feature_set = "ALL" # Required for SCPs
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
}

# 2. Create Departments (Organizational Units - OUs)
resource "aws_organizations_organizational_unit" "security" {
  name      = "Security-Prod"
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads-Prod"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# 3. Define the Policies (SCPs)
resource "aws_organizations_policy" "protect_cloudtrail" {
  name        = "Deny-CloudTrail-Tampering"
  description = "Prevents stopping or deleting CloudTrail logging"
  content     = file("${path.module}/policies/scp_deny_cloudtrail_stop.json")
  type        = "SERVICE_CONTROL_POLICY"
}

resource "aws_organizations_policy" "region_restrict" {
  name        = "Restrict-Regions-US"
  description = "Allows operations only in us-east-1 and us-east-2"
  content = file("${path.module}/policies/scp_region_restriction.json")
  type        = "SERVICE_CONTROL_POLICY"
}

# 4. Attach Policies to the "Workloads" OU
# Logic: Everyone in this folder gets these rules applied automatically.
resource "aws_organizations_policy_attachment" "attach_cloudtrail" {
  policy_id = aws_organizations_policy.protect_cloudtrail.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "attach_regions" {
  policy_id = aws_organizations_policy.region_restrict.id
  target_id = aws_organizations_organizational_unit.workloads.id
}