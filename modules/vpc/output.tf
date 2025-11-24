# Outputs the unique identifier (ID) of the main VPC created in this module.
# This allows other modules or root configuration to reference this VPC.
output "vpc_id" {
    value = aws_vpc.main.id
}

# Outputs the ID of the public subnet.
# Typically used by other modules (e.g., EC2, ALB) that need to launch
# resources in a subnet with internet access via an Internet Gateway.
output "public_subnet_id" {
    value = aws_subnet.public.id
}

# Outputs the ID of the private subnet.
# Commonly used for resources that should not be directly accessible
# from the internet (e.g., databases, internal services).
output "private_subnet_id" {
    value = aws_subnet.private.id
}