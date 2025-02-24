terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# US East 1 (VPC-A) Provider
provider "aws" {
  region = "us-east-1"
  alias  = "use1"
}

# AP Northeast 1 (VPC-B) Provider
provider "aws" {
  region = "ap-northeast-1"
  alias  = "apne1"
}

# Install Python dependencies
resource "null_resource" "install_dependencies" {
  triggers = {
    dependencies_versions = filemd5("${path.module}/requirements.txt")
    source_versions      = filemd5("${path.module}/lambda_function.py")
  }

  provisioner "local-exec" {
    command = <<EOF
      rm -rf ${path.module}/package
      mkdir -p ${path.module}/package
      pip install --target ${path.module}/package -r ${path.module}/requirements.txt
      cp ${path.module}/lambda_function.py ${path.module}/package/
    EOF
  }
}

# Create zip file for Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source_dir  = "${path.module}/package"
  
  depends_on = [null_resource.install_dependencies]
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# VPC-A (us-east-1)
resource "aws_vpc" "vpc_a" {
  provider = aws.use1
  
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "vpc-multiregion-use1"
    Purpose = "Cross-Region VPC Connection Testing"
    Region  = "us-east-1"
  }
}

# VPC-B (ap-northeast-1)
resource "aws_vpc" "vpc_b" {
  provider = aws.apne1
  
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "vpc-multiregion-apne1"
    Purpose = "Cross-Region VPC Connection Testing"
    Region  = "ap-northeast-1"
  }
}

# Public Subnet for VPC-A
resource "aws_subnet" "vpc_a_public" {
  provider = aws.use1
  
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vpc-multiregion-use1-public-1a"
    Type = "Public"
  }
}

# Private Subnet for VPC-A
resource "aws_subnet" "vpc_a_private" {
  provider = aws.use1
  
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vpc-multiregion-use1-private-1a"
    Type = "Private"
  }
}

# Public Subnet for VPC-B
resource "aws_subnet" "vpc_b_public" {
  provider = aws.apne1
  
  vpc_id            = aws_vpc.vpc_b.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "vpc-multiregion-apne1-public-1a"
    Type = "Public"
  }
}

# Private Subnet for VPC-B
resource "aws_subnet" "vpc_b_private" {
  provider = aws.apne1
  
  vpc_id            = aws_vpc.vpc_b.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "vpc-multiregion-apne1-private-1a"
    Type = "Private"
  }
}

# Internet Gateway for VPC-A
resource "aws_internet_gateway" "vpc_a_igw" {
  provider = aws.use1
  vpc_id   = aws_vpc.vpc_a.id

  tags = {
    Name = "vpc-multiregion-use1-igw"
  }
}

# Internet Gateway for VPC-B
resource "aws_internet_gateway" "vpc_b_igw" {
  provider = aws.apne1
  vpc_id   = aws_vpc.vpc_b.id

  tags = {
    Name = "vpc-multiregion-apne1-igw"
  }
}

# Elastic IP for NAT Gateway VPC-A
resource "aws_eip" "vpc_a_nat" {
  provider = aws.use1
  domain   = "vpc"
  
  tags = {
    Name = "vpc-multiregion-use1-nat-eip"
  }
}

# Elastic IP for NAT Gateway VPC-B
resource "aws_eip" "vpc_b_nat" {
  provider = aws.apne1
  domain   = "vpc"
  
  tags = {
    Name = "vpc-multiregion-apne1-nat-eip"
  }
}

# NAT Gateway for VPC-A
resource "aws_nat_gateway" "vpc_a_nat" {
  provider = aws.use1
  
  allocation_id = aws_eip.vpc_a_nat.id
  subnet_id     = aws_subnet.vpc_a_public.id

  tags = {
    Name = "vpc-multiregion-use1-nat"
  }
}

# NAT Gateway for VPC-B
resource "aws_nat_gateway" "vpc_b_nat" {
  provider = aws.apne1
  
  allocation_id = aws_eip.vpc_b_nat.id
  subnet_id     = aws_subnet.vpc_b_public.id

  tags = {
    Name = "vpc-multiregion-apne1-nat"
  }
}

# Transit Gateway in us-east-1
resource "aws_ec2_transit_gateway" "tgw_use1" {
  provider = aws.use1
  
  description = "Transit Gateway for VPC-A in us-east-1"
  
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  
  tags = {
    Name = "vpc-multiregion-use1-tgw"
  }
}

# Transit Gateway in ap-northeast-1
resource "aws_ec2_transit_gateway" "tgw_apne1" {
  provider = aws.apne1
  
  description = "Transit Gateway for VPC-B in ap-northeast-1"
  
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  
  tags = {
    Name = "vpc-multiregion-apne1-tgw"
  }
}

# Transit Gateway Peering Connection
resource "aws_ec2_transit_gateway_peering_attachment" "tgw_peering" {
  provider = aws.use1

  peer_account_id         = "075144853076"
  peer_region            = "ap-northeast-1"
  peer_transit_gateway_id = aws_ec2_transit_gateway.tgw_apne1.id
  transit_gateway_id      = aws_ec2_transit_gateway.tgw_use1.id

  tags = {
    Name = "vpc-multiregion-tgw-peering"
  }
}

# Accept the peering attachment in ap-northeast-1
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tgw_peering_accepter" {
  provider = aws.apne1

  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.tgw_peering.id

  tags = {
    Name = "vpc-multiregion-tgw-peering-accepter"
  }
}

# Transit Gateway VPC Attachment for VPC-A
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_a_attachment" {
  provider = aws.use1

  subnet_ids         = [aws_subnet.vpc_a_private.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw_use1.id
  vpc_id            = aws_vpc.vpc_a.id
  
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "vpc-multiregion-use1-tgw-attachment"
  }
}

# Transit Gateway VPC Attachment for VPC-B
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_b_attachment" {
  provider = aws.apne1

  subnet_ids         = [aws_subnet.vpc_b_private.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw_apne1.id
  vpc_id            = aws_vpc.vpc_b.id
  
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "vpc-multiregion-apne1-tgw-attachment"
  }
}

# Transit Gateway Route Table for us-east-1
resource "aws_ec2_transit_gateway_route_table" "tgw_rt_use1" {
  provider = aws.use1

  transit_gateway_id = aws_ec2_transit_gateway.tgw_use1.id

  tags = {
    Name = "vpc-multiregion-use1-tgw-rt"
  }
}

# Transit Gateway Route Table for ap-northeast-1
resource "aws_ec2_transit_gateway_route_table" "tgw_rt_apne1" {
  provider = aws.apne1

  transit_gateway_id = aws_ec2_transit_gateway.tgw_apne1.id

  tags = {
    Name = "vpc-multiregion-apne1-tgw-rt"
  }
}

# Route to VPC-B through TGW Peering in us-east-1
resource "aws_ec2_transit_gateway_route" "to_vpc_b" {
  provider = aws.use1

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peering_accepter,
    aws_ec2_transit_gateway_route_table_association.vpc_a_rt_association,
    aws_ec2_transit_gateway_route_table_association.vpc_b_rt_association
  ]

  destination_cidr_block         = "10.1.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.tgw_peering.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt_use1.id
}

# Route to VPC-A through TGW Peering in ap-northeast-1
resource "aws_ec2_transit_gateway_route" "to_vpc_a" {
  provider = aws.apne1

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peering_accepter,
    aws_ec2_transit_gateway_route_table_association.vpc_a_rt_association,
    aws_ec2_transit_gateway_route_table_association.vpc_b_rt_association
  ]

  destination_cidr_block         = "10.0.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.tgw_peering.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt_apne1.id
}

# Associate VPC-A attachment with TGW route table
resource "aws_ec2_transit_gateway_route_table_association" "vpc_a_rt_association" {
  provider = aws.use1

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_a_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt_use1.id
}

# Associate VPC-B attachment with TGW route table
resource "aws_ec2_transit_gateway_route_table_association" "vpc_b_rt_association" {
  provider = aws.apne1

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_b_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt_apne1.id
}

# Update VPC-A private route table
resource "aws_route" "vpc_a_to_vpc_b" {
  provider = aws.use1

  depends_on = [
    aws_ec2_transit_gateway_route.to_vpc_b,
    aws_ec2_transit_gateway_route.to_vpc_a
  ]

  route_table_id         = aws_route_table.vpc_a_private.id
  destination_cidr_block = "10.1.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw_use1.id
}

# Update VPC-B private route table
resource "aws_route" "vpc_b_to_vpc_a" {
  provider = aws.apne1

  depends_on = [
    aws_ec2_transit_gateway_route.to_vpc_b,
    aws_ec2_transit_gateway_route.to_vpc_a
  ]

  route_table_id         = aws_route_table.vpc_b_private.id
  destination_cidr_block = "10.0.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw_apne1.id
}

# Route Tables for VPC-A
resource "aws_route_table" "vpc_a_public" {
  provider = aws.use1
  vpc_id   = aws_vpc.vpc_a.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_a_igw.id
  }

  tags = {
    Name = "vpc-multiregion-use1-public-rt"
  }
}

resource "aws_route_table" "vpc_a_private" {
  provider = aws.use1
  vpc_id   = aws_vpc.vpc_a.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc_a_nat.id
  }

  tags = {
    Name = "vpc-multiregion-use1-private-rt"
  }
}

# Route Tables for VPC-B
resource "aws_route_table" "vpc_b_public" {
  provider = aws.apne1
  vpc_id   = aws_vpc.vpc_b.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_b_igw.id
  }

  tags = {
    Name = "vpc-multiregion-apne1-public-rt"
  }
}

resource "aws_route_table" "vpc_b_private" {
  provider = aws.apne1
  vpc_id   = aws_vpc.vpc_b.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc_b_nat.id
  }

  tags = {
    Name = "vpc-multiregion-apne1-private-rt"
  }
}

# Route Table Associations for VPC-A
resource "aws_route_table_association" "vpc_a_public" {
  provider = aws.use1
  
  subnet_id      = aws_subnet.vpc_a_public.id
  route_table_id = aws_route_table.vpc_a_public.id
}

resource "aws_route_table_association" "vpc_a_private" {
  provider = aws.use1
  
  subnet_id      = aws_subnet.vpc_a_private.id
  route_table_id = aws_route_table.vpc_a_private.id
}

# Route Table Associations for VPC-B
resource "aws_route_table_association" "vpc_b_public" {
  provider = aws.apne1
  
  subnet_id      = aws_subnet.vpc_b_public.id
  route_table_id = aws_route_table.vpc_b_public.id
}

resource "aws_route_table_association" "vpc_b_private" {
  provider = aws.apne1
  
  subnet_id      = aws_subnet.vpc_b_private.id
  route_table_id = aws_route_table.vpc_b_private.id
}

# Security Group for Lambda in VPC-A
resource "aws_security_group" "lambda" {
  provider = aws.use1
  
  name        = "vpc-multiregion-use1-lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = aws_vpc.vpc_a.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-multiregion-use1-lambda-sg"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  provider = aws.use1
  
  name = "vpc-multiregion-use1-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "vpc-multiregion-use1-lambda-role"
  }
}

# IAM Policy for Lambda VPC execution
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  provider = aws.use1
  
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda Function
resource "aws_lambda_function" "test_lambda" {
  provider = aws.use1
  
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "vpc-multiregion-use1-lambda"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.handler"
  runtime         = "python3.13"
  timeout         = 30

  vpc_config {
    subnet_ids         = [aws_subnet.vpc_a_private.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = {
    Name = "vpc-multiregion-use1-lambda"
  }
}
