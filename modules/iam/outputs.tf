# Exposes the EC2 instance profile name so other modules or root configurations can consume it.
output "instance_profile_name" { value = aws_iam_instance_profile.ec2_profile.name }