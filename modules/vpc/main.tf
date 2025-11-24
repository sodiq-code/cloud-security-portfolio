# modules/vpc/main.tf

# Define a VPC resource named "main"
resource "aws_vpc" "main" {                          # Create an AWS VPC named "main"
    cidr_block           = var.vpc_cidr              # Use the CIDR block passed via variable vpc_cidr
    enable_dns_support   = true                      # Enable internal DNS resolution in the VPC
    enable_dns_hostnames = true                      # Enable DNS hostnames for instances with public IPs

    tags = {                                          # Add metadata tags to the VPC
        Name = "${var.environment}-vpc"              # Name tag combining environment (e.g., dev) and suffix "vpc"
    }
}

# Define an Internet Gateway resource named "igw"
resource "aws_internet_gateway" "igw" {              # Create an Internet Gateway for outbound internet access
    vpc_id = aws_vpc.main.id                         # Attach the Internet Gateway to the created VPC

    tags = {                                          # Add metadata tags to the Internet Gateway
        Name = "${var.environment}-igw"              # Name tag combining environment and suffix "igw"
    }
}

# Define a public subnet resource
resource "aws_subnet" "public" {                     # Create a public subnet resource
    vpc_id                  = aws_vpc.main.id        # Place the subnet in the previously created VPC
    cidr_block              = var.public_subnet_cidr # Use CIDR for the public subnet from variable
    map_public_ip_on_launch = true                   # Auto-assign public IPs to instances launched here
    availability_zone       = "${var.region}a"       # Set the subnet to the first AZ in the given region

    tags = {                                          # Add metadata tags to the public subnet
        Name = "${var.environment}-public-subnet"    # Name tag marking this as the environment’s public subnet
    }
}

# Define a private subnet resource
resource "aws_subnet" "private" {                    # Create a private subnet resource
    vpc_id            = aws_vpc.main.id              # Place the subnet in the same VPC as the public subnet
    cidr_block        = var.private_subnet_cidr      # Use CIDR for the private subnet from variable
    availability_zone = "${var.region}a"             # Use the same AZ as the public subnet for simplicity

    tags = {                                          # Add metadata tags to the private subnet
        Name = "${var.environment}-private-subnet"   # Name tag marking this as the environment’s private subnet
    }
}

# Define a route table for the public subnet
resource "aws_route_table" "public" {                # Create a route table for public subnet routing
    vpc_id = aws_vpc.main.id                         # Associate the route table with the created VPC

    route {                                           # Define a route in this route table
        cidr_block = "0.0.0.0/0"                     # Match all IPv4 addresses (default route)
        gateway_id = aws_internet_gateway.igw.id     # Send traffic to the attached Internet Gateway
    }

    tags = {                                          # Add metadata tags to the public route table
        Name = "${var.environment}-public-rt"        # Name tag marking this as the environment’s public route table
    }
}

# Associate the public route table with the public subnet
resource "aws_route_table_association" "public" {    # Link the public route table to the public subnet
    subnet_id      = aws_subnet.public.id            # ID of the public subnet to be associated
    route_table_id = aws_route_table.public.id       # ID of the public route table to use for routing
}