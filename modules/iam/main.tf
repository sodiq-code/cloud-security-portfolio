# IAM role assumed by EC2 instances
resource "aws_iam_role" "ec2_role" {
    name = "${var.environment}-ec2-role"

    # Trust policy ensuring that only EC2 service principals can assume the role
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })
}

# Least-privilege S3 read-only policy for scoped bucket access
resource "aws_iam_policy" "s3_read_only" {
    name        = "${var.environment}-s3-read-policy"
    description = "Allow EC2 to read from specific S3 bucket"

    # Permissions granted to the role; currently global, to be constrained to bucket ARNs
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "s3:ListBucket",
                    "s3:GetObject"
                ]
                Effect   = "Allow"
                Resource = "*" # replace with specific bucket and object ARNs for stronger least-privilege
            }
        ]
    })
}

# Attach the S3 read-only policy to the EC2 IAM role
resource "aws_iam_role_policy_attachment" "attach_s3" {
    role       = aws_iam_role.ec2_role.name
    policy_arn = aws_iam_policy.s3_read_only.arn
}

# Instance profile exposing the IAM role to EC2 instances via metadata service
resource "aws_iam_instance_profile" "ec2_profile" {
    name = "${var.environment}-ec2-profile"
    role = aws_iam_role.ec2_role.name
}
