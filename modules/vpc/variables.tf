# CIDR block for the main VPC where all resources will be provisioned.
# Default covers 65,536 IPs (10.0.0.0 - 10.0.255.255).
variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

# CIDR block for the public subnet.
# Used for resources that need direct internet access (e.g., NAT gateways, public load balancers, bastion hosts).
variable "public_subnet_cidr" {
    default = "10.0.1.0/24"
}

# CIDR block for the private subnet.
# Used for internal resources (e.g., application servers, databases) without direct internet exposure.
variable "private_subnet_cidr" {
    default = "10.0.2.0/24"
}

# Logical name of the deployment environment (e.g., "dev", "staging", "prod").
# Commonly used for tagging and naming resources for easier identification.
variable "environment" {
    type = string
}

# AWS region where the VPC and related resources will be created.
# Default is the N. Virginia region.
variable "region" {
    default = "us-east-1"
}