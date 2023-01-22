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