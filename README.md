# MultiCloud-VPC-POC

[![Made with AI](https://img.shields.io/badge/made_with_AI-Claude_3.5_Sonnet-green?style=for-the-badge)](https://github.com/higumadev/MultiCloud-VPC-POC)

## Description
MultiCloud-VPC-POC is a proof-of-concept (POC) repository focused on validating Virtual Private Cloud (VPC) connectivity across major cloud providers (AWS, GCP, Azure) and between different regions within the same cloud. This project aims to explore and demonstrate best practices for VPC peering, transit gateways, and hybrid network architectures, offering reproducible prototypes and testing scenarios for multi-cloud and multi-region networking solutions.

## Features
- 🔗 **Cross-Cloud VPC Interconnectivity:** Establish and validate network links between AWS, GCP, and Azure VPCs.
- 🌍 **Multi-Region VPC Peering:** Test VPC connectivity within different regions of the same cloud provider.
- 🧪 **Prototyping and Testing:** Provide example code, Terraform scripts, and configuration templates for quick deployment.
- 🚦 **Connectivity Validation:** Implement tools and scripts to test latency, throughput, and packet loss across network boundaries.
- 📄 **Documentation and Demos:** Include detailed setup guides and use case demonstrations.

## Prerequisites
- AWS, GCP, and Azure accounts with sufficient permissions
- [Terraform](https://www.terraform.io/downloads) installed
- CLI tools for AWS, GCP, and Azure (`awscli`, `gcloud`, `az`)

## Getting Started

### Clone the Repository
```sh
git clone https://github.com/your-username/MultiCloud-VPC-POC.git
cd MultiCloud-VPC-POC
```

### Setup Environment
1. Configure cloud provider credentials:
```sh
aws configure
gcloud auth login
az login
```
2. Initialize Terraform modules:
```sh
terraform init
```

### Deploy VPCs
```sh
terraform apply
```
Follow the prompts to approve the deployment.

## Project Structure

This repository contains two main implementations for multi-region VPC connectivity:

### aws-multi-region-peering-vpc
Demonstrates VPC peering between different AWS regions. However, there are some important limitations:
- If VPC A has an internet gateway, resources in VPC B cannot use VPC A's internet gateway to access the internet
- If VPC A has a NAT device, resources in VPC B cannot use VPC A's NAT device to access the internet
- https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html

### aws-multi-region-tgw-vpc
Explores Transit Gateway implementation for connecting VPCs across regions. This implementation is currently under research and development.

## Testing Connectivity
- Run network validation scripts in the `scripts` directory:
```sh
bash scripts/test-connectivity.sh
```
- Review the output for latency, throughput, and connection status.

## Cleanup
```sh
terraform destroy
```

## Contributing
Contributions are welcome! Please open issues or submit pull requests for improvements.

## License
This project is licensed under the MIT License.
