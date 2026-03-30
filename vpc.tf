# 1. Create the VPC
resource "aws_vpc" "auto-healer-vpc" {
  cidr_block           = var.vpc_cidr_healer
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "auto-healer-vpc"
    Project     = "Resume-Project"
    Environment = "Dev"
  }
}

# 2. Create the Internet Gateway (The "Door")
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.auto-healer-vpc.id

  tags = {
    Name = "auto-healer-igw-1"
  }
}

# 3. Create the Public Subnet (The "Front Porch")
resource "aws_subnet" "auto-healer-public" {
  vpc_id                  = aws_vpc.auto-healer-vpc.id
  cidr_block              = var.public_subnet_cidr_healer
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a" # Since you are in Ohio

  tags = {
    Name = "public-subnet-healer-1"
  }
}

# 4. Create a Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.auto-healer-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "auto-healer-public-rt"
  }
}

# 5. Associate the Subnet with the Route Table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.auto-healer-public.id
  route_table_id = aws_route_table.public_rt.id
}