# Create Lambda deployment package
resource "null_resource" "lambda_dependencies" {
  triggers = {
    dependencies_versions = filemd5("${path.module}/requirements.txt")
    source_versions      = filemd5("${path.module}/lambda_function.py")
  }

  provisioner "local-exec" {
    command = <<EOF
      rm -rf ${path.module}/package
      mkdir -p ${path.module}/package
      pip3 install --target ${path.module}/package -r ${path.module}/requirements.txt
      cp ${path.module}/lambda_function.py ${path.module}/package/
    EOF
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source_dir  = "${path.module}/package"
  
  depends_on = [null_resource.lambda_dependencies]
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  provider = aws.use1
  name     = "lambda_checkip_role"

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
}

# IAM policy for Lambda VPC access
resource "aws_iam_role_policy_attachment" "lambda_vpc_policy" {
  provider   = aws.use1
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Security group for Lambda functions
resource "aws_security_group" "lambda_sg" {
  provider    = aws.use1
  name        = "lambda_sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.use1.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-sg"
  }
}

# Lambda function in local NAT subnet
resource "aws_lambda_function" "checkip_local" {
  provider      = aws.use1
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "checkip-local-nat"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"  # Using 3.11 as 3.13 is not yet available in AWS Lambda
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout     = 30

  vpc_config {
    subnet_ids         = [aws_subnet.use1_private_local.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_policy,
    data.archive_file.lambda_zip
  ]

  tags = {
    Name = "checkip-local-nat"
  }
}

# Lambda function in remote NAT subnet
resource "aws_lambda_function" "checkip_remote" {
  provider      = aws.use1
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "checkip-remote-nat"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"  # Using 3.11 as 3.13 is not yet available in AWS Lambda
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout     = 30

  vpc_config {
    subnet_ids         = [aws_subnet.use1_private_remote.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_policy,
    data.archive_file.lambda_zip
  ]

  tags = {
    Name = "checkip-remote-nat"
  }
}

# Security group for Lambda functions in APNE1
resource "aws_security_group" "lambda_sg_apne1" {
  provider    = aws.apne1
  name        = "lambda_sg_apne1"
  description = "Security group for Lambda functions in APNE1"
  vpc_id      = aws_vpc.apne1.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-sg-apne1"
  }
}

# IAM role for Lambda in APNE1
resource "aws_iam_role" "lambda_role_apne1" {
  provider = aws.apne1
  name     = "lambda_checkip_role_apne1"

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
}

# IAM policy for Lambda VPC access in APNE1
resource "aws_iam_role_policy_attachment" "lambda_vpc_policy_apne1" {
  provider   = aws.apne1
  role       = aws_iam_role.lambda_role_apne1.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda function in APNE1 private subnet
resource "aws_lambda_function" "checkip_apne1" {
  provider      = aws.apne1
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "checkip-apne1-nat"
  role          = aws_iam_role.lambda_role_apne1.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"  # Using 3.11 as 3.13 is not yet available in AWS Lambda
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout     = 30

  vpc_config {
    subnet_ids         = [aws_subnet.apne1_private.id]
    security_group_ids = [aws_security_group.lambda_sg_apne1.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_policy_apne1,
    data.archive_file.lambda_zip
  ]

  tags = {
    Name = "checkip-apne1-nat"
  }
}
