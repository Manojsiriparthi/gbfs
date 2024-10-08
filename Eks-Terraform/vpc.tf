# VPC creation
resource "aws_vpc" "gbfs_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "gbfs-vpc"
  }
}

# Subnet 1
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.gbfs_vpc.id
  cidr_block              = var.subnet1_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "gbfs-subnet-1"
  }
}

# Subnet 2
resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.gbfs_vpc.id
  cidr_block              = var.subnet2_cidr
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "gbfs-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.gbfs_vpc.id

  tags = {
    Name = "gbfs-igw"
  }
}

# Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.gbfs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "gbfs-route-table"
  }
}

# Route Table Associations
resource "aws_route_table_association" "subnet1_rta" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "subnet2_rta" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt.id
}

# Security Groups
resource "aws_security_group" "eks_sg" {
  vpc_id = aws_vpc.gbfs_vpc.id

  # Allow traffic from the EKS cluster nodes to the MySQL instance
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # Restrict this to the EKS node security group (you may need to create a separate SG for EKS nodes)
    security_groups = [aws_security_group.eks_nodes_sg.id]  # Allow only EKS nodes to connect to MySQL
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule for all traffic within the VPC (consider restricting this further)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gbfs-sg"
  }
}

# Security Group for EKS Nodes
resource "aws_security_group" "eks_nodes_sg" {
  vpc_id = aws_vpc.gbfs_vpc.id

  # Allow outbound traffic to MySQL RDS instance
  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic to RDS; restrict in production
  }

  # General outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gbfs-eks-nodes-sg"
  }
}

