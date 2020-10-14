provider "aws" {
  region                  = var.region_name
  shared_credentials_file = var.credentials
  profile                 = var.profile
}

resource "aws_vpc" "vpc1" {
  cidr_block           = var.vpc[var.vpccidr]
  enable_dns_hostnames = var.vpc[var.vpcenablehost]
  tags = {
    Name = var.vpc[var.vpccidr]
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc1.id
  availability_zone       = var.availabilityZone[0]
  map_public_ip_on_launch = var.subnet_map_public
  cidr_block              = var.subnetcidr[0]
  tags = {
    Name = var.subnetname[0]
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc1.id
  map_public_ip_on_launch = var.subnet_map_public
  availability_zone       = var.availabilityZone[1]
  cidr_block              = var.subnetcidr[1]
  tags = {
    Name = var.subnetname[1]
  }
}

resource "aws_subnet" "subnet3" {
  vpc_id                  = aws_vpc.vpc1.id
  map_public_ip_on_launch = var.subnet_map_public
  availability_zone       = var.availabilityZone[2]
  cidr_block              = var.subnetcidr[2]
  tags = {
    Name = var.subnetname[2]
  }
}

resource "aws_internet_gateway" "internetgateway" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name = var.ig_name
  }
}
resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = var.publicroute
    gateway_id = aws_internet_gateway.internetgateway.id
  }
  tags = {
    Name = var.route_table_name
  }
}

resource "aws_main_route_table_association" "associate_vpc" {
  vpc_id         = aws_vpc.vpc1.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_route_table_association" "associate_subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_route_table_association" "associate_subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_route_table_association" "associate_subnet3" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_security_group" "allow_all" {
  name   = var.securityname
  vpc_id = aws_vpc.vpc1.id

  ingress {
    description = var.securityname
    from_port   = var.ingress_from_port
    to_port     = var.ingress_to_port
    protocol    = var.publicprotocol
    cidr_blocks = [var.publicroute]
  }

  egress {
    from_port   = var.egress_from_port
    to_port     = var.egress_to_port
    protocol    = var.publicprotocol
    cidr_blocks = [var.publicroute]
  }

  tags = {
    Name = var.securityname
  }
}
