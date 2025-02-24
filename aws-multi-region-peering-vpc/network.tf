# Subnets in AP Northeast 1
resource "aws_subnet" "apne1_public" {
  provider = aws.apne1
  
  vpc_id            = aws_vpc.apne1.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "apne1-public-subnet"
  }
}

resource "aws_subnet" "apne1_private" {
  provider = aws.apne1
  
  vpc_id            = aws_vpc.apne1.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "apne1-private-subnet"
  }
}

# Subnets in US East 1
resource "aws_subnet" "use1_public" {
  provider = aws.use1
  
  vpc_id            = aws_vpc.use1.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "use1-public-subnet"
  }
}

resource "aws_subnet" "use1_private_local" {
  provider = aws.use1
  
  vpc_id            = aws_vpc.use1.id
  cidr_block        = "10.2.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "use1-private-local-subnet"
  }
}

resource "aws_subnet" "use1_private_remote" {
  provider = aws.use1
  
  vpc_id            = aws_vpc.use1.id
  cidr_block        = "10.2.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "use1-private-remote-subnet"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "use1_nat" {
  provider = aws.use1
  domain   = "vpc"

  tags = {
    Name = "use1-nat-eip"
  }
}

resource "aws_eip" "apne1_nat" {
  provider = aws.apne1
  domain   = "vpc"

  tags = {
    Name = "apne1-nat-eip"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "use1_nat" {
  provider      = aws.use1
  allocation_id = aws_eip.use1_nat.id
  subnet_id     = aws_subnet.use1_public.id

  depends_on = [aws_internet_gateway.use1_igw]

  tags = {
    Name = "use1-nat-gateway"
  }
}

resource "aws_nat_gateway" "apne1_nat" {
  provider      = aws.apne1
  allocation_id = aws_eip.apne1_nat.id
  subnet_id     = aws_subnet.apne1_public.id

  depends_on = [aws_internet_gateway.apne1_igw]

  tags = {
    Name = "apne1-nat-gateway"
  }
}

# Internet Gateway for US East 1
resource "aws_internet_gateway" "use1_igw" {
  provider = aws.use1
  vpc_id   = aws_vpc.use1.id

  tags = {
    Name = "use1-igw"
  }
}

# Internet Gateway for AP Northeast 1
resource "aws_internet_gateway" "apne1_igw" {
  provider = aws.apne1
  vpc_id   = aws_vpc.apne1.id

  tags = {
    Name = "apne1-igw"
  }
}

# Route Tables for AP Northeast 1
resource "aws_route_table" "apne1_public" {
  provider = aws.apne1
  vpc_id   = aws_vpc.apne1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.apne1_igw.id
  }

  route {
    cidr_block = aws_vpc.use1.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection_accepter.apne1_accepter.id
  }

  tags = {
    Name = "apne1-public-rt"
  }
}

resource "aws_route_table" "apne1_private" {
  provider = aws.apne1
  vpc_id   = aws_vpc.apne1.id

  depends_on = [aws_nat_gateway.apne1_nat]

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.apne1_nat.id
  }

  route {
    cidr_block = aws_vpc.use1.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection_accepter.apne1_accepter.id
  }

  tags = {
    Name = "apne1-private-rt"
  }
}

# Route Tables for US East 1
resource "aws_route_table" "use1_public" {
  provider = aws.use1
  vpc_id   = aws_vpc.use1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.use1_igw.id
  }

  route {
    cidr_block = aws_vpc.apne1.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.use1_to_apne1.id
  }

  tags = {
    Name = "use1-public-rt"
  }
}

resource "aws_route_table" "use1_private_local" {
  provider = aws.use1
  vpc_id   = aws_vpc.use1.id

  depends_on = [aws_nat_gateway.use1_nat]

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.use1_nat.id
  }

  route {
    cidr_block = aws_vpc.apne1.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.use1_to_apne1.id
  }

  tags = {
    Name = "use1-private-local-rt"
  }
}

resource "aws_route_table" "use1_private_remote" {
  provider = aws.use1
  vpc_id   = aws_vpc.use1.id

  route {
    cidr_block = "0.0.0.0/0"
    vpc_peering_connection_id = aws_vpc_peering_connection.use1_to_apne1.id
  }

  route {
    cidr_block = aws_vpc.apne1.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.use1_to_apne1.id
  }

  tags = {
    Name = "use1-private-remote-rt"
  }
}

# NACL for APNE1 private subnet
resource "aws_network_acl" "apne1_private" {
  provider = aws.apne1
  vpc_id   = aws_vpc.apne1.id

  # 允许所有入站流量
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # 特别允许来自 USE1 VPC 的入站流量
  ingress {
    protocol   = "-1"
    rule_no    = 90
    action     = "allow"
    cidr_block = aws_vpc.use1.cidr_block
    from_port  = 0
    to_port    = 0
  }

  # 允许所有出站流量
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # 特别允许到 USE1 VPC 的出站流量
  egress {
    protocol   = "-1"
    rule_no    = 90
    action     = "allow"
    cidr_block = aws_vpc.use1.cidr_block
    from_port  = 0
    to_port    = 0
  }

  subnet_ids = [aws_subnet.apne1_private.id]

  tags = {
    Name = "apne1-private-nacl"
  }
}

# NACL for USE1 private remote subnet
resource "aws_network_acl" "use1_private_remote" {
  provider = aws.use1
  vpc_id   = aws_vpc.use1.id

  # 允许所有入站流量
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # 特别允许来自 APNE1 VPC 的入站流量
  ingress {
    protocol   = "-1"
    rule_no    = 90
    action     = "allow"
    cidr_block = aws_vpc.apne1.cidr_block
    from_port  = 0
    to_port    = 0
  }

  # 允许所有出站流量
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # 特别允许到 APNE1 VPC 的出站流量
  egress {
    protocol   = "-1"
    rule_no    = 90
    action     = "allow"
    cidr_block = aws_vpc.apne1.cidr_block
    from_port  = 0
    to_port    = 0
  }

  subnet_ids = [aws_subnet.use1_private_remote.id]

  tags = {
    Name = "use1-private-remote-nacl"
  }
}

# Route Table Associations for AP Northeast 1
resource "aws_route_table_association" "apne1_public" {
  provider = aws.apne1
  subnet_id      = aws_subnet.apne1_public.id
  route_table_id = aws_route_table.apne1_public.id
}

resource "aws_route_table_association" "apne1_private" {
  provider = aws.apne1
  subnet_id      = aws_subnet.apne1_private.id
  route_table_id = aws_route_table.apne1_private.id
}

# Route Table Associations for US East 1
resource "aws_route_table_association" "use1_public" {
  provider       = aws.use1
  subnet_id      = aws_subnet.use1_public.id
  route_table_id = aws_route_table.use1_public.id
}

resource "aws_route_table_association" "use1_private_local" {
  provider       = aws.use1
  subnet_id      = aws_subnet.use1_private_local.id
  route_table_id = aws_route_table.use1_private_local.id
}

resource "aws_route_table_association" "use1_private_remote" {
  provider       = aws.use1
  subnet_id      = aws_subnet.use1_private_remote.id
  route_table_id = aws_route_table.use1_private_remote.id
}
