# AWS Multi-Region VPC Peering Connection

This project demonstrates how to set up VPC peering between two AWS regions (AP Northeast 1 and US East 1) using Terraform.

## Architecture Overview

- AP Northeast 1 Region (ap-northeast-1):
  - VPC with CIDR: 10.1.0.0/16
  - Public Subnet: 10.1.1.0/24
  - Private Subnet: 10.1.2.0/24

- US East 1 Region (us-east-1):
  - VPC with CIDR: 10.2.0.0/16
  - Public Subnet: 10.2.1.0/24
  - Private Subnet: 10.2.2.0/24

The VPCs are connected via a VPC peering connection, allowing resources in both regions to communicate with each other using private IP addresses.

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (version >= 1.2.0)
3. AWS account with permissions to create VPCs and VPC peering connections

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the planned changes:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. To destroy the infrastructure:
   ```bash
   terraform destroy
   ```

## Network Configuration

- Each region has both public and private subnets
- Route tables are configured to route traffic between the VPCs through the peering connection
- The peering connection is created from AP Northeast 1 and accepted in US East 1 automatically

## Security Considerations

- Make sure to configure appropriate security groups and NACLs (not included in this basic setup)
- Consider using AWS Organizations for better management if working with multiple accounts
- Review the route tables to ensure only necessary traffic is allowed between regions

## Notes

- VPC peering connections are charged based on data transfer
- VPC peering does not support transitive peering (if you need to connect more than two VPCs, consider using Transit Gateway)
- Each VPC must have non-overlapping CIDR blocks
