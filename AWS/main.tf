# Create a VPC
resource "aws_vpc" "acg_vpc" {
  cidr_block = "192.168.212.0/24"

  tags = {
    Environment = var.env
    Name        = "${var.prefix}_${var.env}_vpc"
  }
}

# Create Subnets
data "aws_availability_zones" "az_list" {}

resource "aws_subnet" "acg_app_subnets" {
  count             = 2
  vpc_id            = aws_vpc.acg_vpc.id
  cidr_block        = element(var.app_subnets, count.index)
  availability_zone = element(data.aws_availability_zones.az_list.names, count.index)

  tags = {
    Name = "${var.prefix}_${var.env}_app_${count.index}"
  }
}

resource "aws_subnet" "acg_data_subnets" {
  count             = 2
  vpc_id            = aws_vpc.acg_vpc.id
  cidr_block        = element(var.data_subnets, count.index)
  availability_zone = element(data.aws_availability_zones.az_list.names, count.index)

  tags = {
    Name = "${var.prefix}_${var.env}_data_${count.index}"
  }
}

# Create VPC Endpoint - S3 Gateway
resource "aws_vpc_endpoint" "acg_vpce_s3" {
  vpc_id       = aws_vpc.acg_vpc.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = {
    Environment = var.env
  }
}

# Create IGW
resource "aws_internet_gateway" "acg_igw" {
  vpc_id = aws_vpc.acg_vpc.id

  tags = {
    Name = "${var.prefix}_${var.env}_igw"
  }
}

resource "aws_default_route_table" "acg_default_rtb" {
  default_route_table_id = aws_vpc.acg_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.acg_igw.id
  }

  tags = {
    Environment = var.env
    Name        = "${var.prefix}_${var.env}_main"
  }
}

# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "dev-key"
  public_key = var.dev_key
}

# Security Group
resource "aws_security_group" "ssh_sg" {
  name = "SSH Security Group"
  vpc_id = aws_vpc.acg_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 - Jenkins Instance
data "cloudinit_config" "jenkins_config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = file("${path.module}/jenkins.yml")
  }
}

data "aws_ami" "amz_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*", "x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "jenkins_master" {
  ami           = data.aws_ami.amz_linux.id
  instance_type = "t2.micro"
  key_name = "dev-key"

  subnet_id = aws_subnet.acg_app_subnets[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ssh_sg.id]

  tags = {
    Name = "Jenkins-Master"
  }

  user_data = data.cloudinit_config.jenkins_config.rendered
}