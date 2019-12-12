resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.group}-${var.env}-vpc1"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

##################
# Public subnets #
##################

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.group}-${var.env}-vpc1-internet-gateway"
  }
}

resource "aws_subnet" "public_subnets" {
  vpc_id = aws_vpc.vpc.id

  count = 3

  cidr_block        = "${cidrsubnet(var.vpc_cidr, 3, count.index)}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"

  tags = {
    Name = "${var.group}-${var.env}-vpc1-${element(data.aws_availability_zones.available.names, count.index)}-public"
  }
}

resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "${var.group}-${var.env}-vpc1-rt-public"
  }
}

resource "aws_route_table_association" "route_table_public_association" {
  count          = 3
  subnet_id      = "${element(aws_subnet.public_subnets.*.id, count.index)}"
  route_table_id = aws_route_table.route_table_public.id
}

###################
# Private subnets #
###################

resource "aws_subnet" "private_subnets" {
  vpc_id = aws_vpc.vpc.id

  count = 3

  cidr_block        = "${cidrsubnet(var.vpc_cidr, 3, count.index + 3)}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"

  tags = {
    Name = "${var.group}-${var.env}-vpc1-${element(data.aws_availability_zones.available.names, count.index)}-private"
  }
}

resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = "${element(aws_subnet.public_subnets.*.id, 0)}"

  tags = {
    Name = "${var.group}-${var.env}-vpc1-nat-gateway"
  }
}

resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "${var.group}-${var.env}-vpc1-rt-private"
  }
}

resource "aws_route_table_association" "route_table_private_association" {
  count          = 3
  subnet_id      = "${element(aws_subnet.private_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.route_table_private.id}"
}
