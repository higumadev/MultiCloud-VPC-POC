terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

# Provider for AP Northeast 1 region (ap-northeast-1)
provider "aws" {
  region = "ap-northeast-1"
  alias  = "apne1"
}

# Provider for US East 1 region (us-east-1)
provider "aws" {
  region = "us-east-1"
  alias  = "use1"
}

# VPC in AP Northeast 1
resource "aws_vpc" "apne1" {
  provider = aws.apne1
  
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "apne1-vpc"
  }
}

# VPC in US East 1
resource "aws_vpc" "use1" {
  provider = aws.use1
  
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "use1-vpc"
  }
}

# VPC Peering connection
resource "aws_vpc_peering_connection" "use1_to_apne1" {
  provider = aws.use1
  
  vpc_id        = aws_vpc.use1.id
  peer_vpc_id   = aws_vpc.apne1.id
  peer_region   = "ap-northeast-1"
  auto_accept   = false

  tags = {
    Name = "use1-to-apne1-peering"
  }
}

# Accept VPC peering connection in AP Northeast 1
resource "aws_vpc_peering_connection_accepter" "apne1_accepter" {
  provider = aws.apne1
  
  vpc_peering_connection_id = aws_vpc_peering_connection.use1_to_apne1.id
  auto_accept              = true

  tags = {
    Name = "apne1-accepter"
  }
}
