# AWS Multi-Region Transit Gateway VPC Architecture

This project demonstrates a multi-region AWS network architecture using Transit Gateway (TGW) to connect VPCs across different regions. The infrastructure is deployed using Terraform and includes Lambda functions for network monitoring.

## Architecture Overview

The infrastructure consists of:

- **VPC-A** in US East 1 (N. Virginia)
- **VPC-B** in AP Northeast 1 (Tokyo)
- Transit Gateway in each region
- Transit Gateway Peering between regions
- Lambda function for network monitoring
- Route tables and necessary networking components

## Prerequisites

- AWS Account
- Terraform ~> 1.0
- Python 3.x
- AWS CLI configured with appropriate credentials

## Project Structure

```
.
├── main.tf                 # Main Terraform configuration
├── lambda_function.py      # Lambda function for network monitoring
├── test_lambda.py         # Tests for Lambda function
├── requirements.txt       # Python dependencies
└── README.md             # This file
```

## Deployment

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

## Network Configuration

- **VPC-A (us-east-1)**:
  - Transit Gateway for local region connectivity
  - Public and private subnets
  - Route tables configured for cross-region routing

- **VPC-B (ap-northeast-1)**:
  - Transit Gateway for local region connectivity
  - Public and private subnets
  - Route tables configured for cross-region routing

## Lambda Function

The included Lambda function monitors network connectivity between the regions. It is automatically deployed with the necessary Python dependencies specified in `requirements.txt`.

## Clean Up

To destroy the infrastructure:
```bash
terraform destroy
```

## Security Considerations

- Ensure proper IAM permissions are configured
- Review and customize security group rules as needed
- Monitor Transit Gateway costs as they are billed by the hour and for data transfer

## Contributing

Feel free to submit issues and enhancement requests.

## License

This project is open-source and available under the MIT License.
