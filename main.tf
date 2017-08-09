# This is a main file implementing AWS VPC Scenario 2
# Features private subnet with a backend with "fake-db" instance
# and a public subnet with a "fake-webserver" instance

# General setup

provider "aws" {
  region = "${var.aws_region}"
}

# Key pairs

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "${var.deployer_public_key}"
}

# VPC setup

resource "aws_vpc" "wn_main" {
  cidr_block = "10.10.0.0/16"

  tags {
    Name = "wn-main"
  }
}

# Private and public subnets inside a vpc

resource "aws_subnet" "wn_primary_public" {
  vpc_id                  = "${aws_vpc.wn_main.id}"
  cidr_block              = "10.10.0.0/24"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "wn-primary-public"
  }
}

resource "aws_subnet" "wn_primary_private" {
  vpc_id            = "${aws_vpc.wn_main.id}"
  cidr_block        = "10.10.1.0/24"
  availability_zone = "us-west-1a"

  tags = {
    Name = "wn-primary-private"
  }
}

# Internet gateway

resource "aws_internet_gateway" "wn_main" {
  vpc_id = "${aws_vpc.wn_main.id}"

  tags {
    Name = "wn-main"
  }
}

# NAT gateway

resource "aws_eip" "wn_nat_primary" {
  vpc = true
}

resource "aws_nat_gateway" "wn_primary" {
  allocation_id = "${aws_eip.wn_nat_primary.id}"
  subnet_id     = "${aws_subnet.wn_primary_public.id}"
}

# Subnet route tables

resource "aws_route_table" "wn_public" {
  vpc_id = "${aws_vpc.wn_main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wn_main.id}"
  }

  tags {
    Name = "wn-public"
  }
}

resource "aws_route_table_association" "wn_assoc_public" {
  subnet_id      = "${aws_subnet.wn_primary_public.id}"
  route_table_id = "${aws_route_table.wn_public.id}"
}

resource "aws_route_table" "wn_primary_private" {
  vpc_id = "${aws_vpc.wn_main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.wn_primary.id}"
  }

  tags {
    Name = "wn-primary-private"
  }
}

resource "aws_route_table_association" "wn_assoc_private" {
  subnet_id      = "${aws_subnet.wn_primary_private.id}"
  route_table_id = "${aws_route_table.wn_primary_private.id}"
}

# Subnet network ACLs

resource "aws_network_acl" "wn_public" {
  vpc_id     = "${aws_vpc.wn_main.id}"
  subnet_ids = [
    "${aws_subnet.wn_primary_public.id}"
  ]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "udp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 5060
    to_port    = 5061
  }

  ingress {
    protocol   = "udp"
    rule_no    = 150
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 10000
    to_port    = 20000
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "10.10.1.0/24"
    from_port  = 22
    to_port    = 22
  }

  egress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }


  tags {
    Name = "wn-public"
  }
}

resource "aws_network_acl" "wn_private" {
  vpc_id = "${aws_vpc.wn_main.id}"
  subnet_ids = [
    "${aws_subnet.wn_primary_private.id}"
  ]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.10.0.0/24"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "10.10.0.0/24"
    from_port  = 1024
    to_port    = 65535
  }

  tags {
    Name = "wn-private"
  }
}

# Security groups

resource "aws_security_group" "test_webserver" {
  vpc_id = "${aws_vpc.wn_main.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = ["${aws_security_group.test_db.id}"]
  }

  tags = {
    Name = "test-webserver"
  }
}

resource "aws_security_group" "test_db" {
  vpc_id = "${aws_vpc.wn_main.id}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "test-db"
  }
}

resource "aws_security_group" "test_ssh" {
  vpc_id = "${aws_vpc.wn_main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "test-ssh"
  }
}

# Servers in private subnet

# fake db server

data "aws_ami" "ubuntu_base_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "fake_db" {
  count                  = 1
  ami                    = "${data.aws_ami.ubuntu_base_ami.id}"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.wn_primary_private.id}"
  vpc_security_group_ids = [
    "${aws_security_group.test_ssh.id}",
    "${aws_security_group.test_db.id}"
  ]

  key_name               = "deployer-key"
  depends_on             = ["aws_internet_gateway.wn_main"]

  tags {
    Name = "fake-db-${count.index}"
  }
}

# Servers in public subnet

resource "aws_instance" "fake_webserver" {
  count                  = 1
  ami                    = "${data.aws_ami.ubuntu_base_ami.id}"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.wn_primary_public.id}"
  vpc_security_group_ids = [
    "${aws_security_group.test_ssh.id}",
    "${aws_security_group.test_webserver.id}"
  ]

  key_name               = "deployer-key"
  depends_on             = ["aws_internet_gateway.wn_main"]

  tags {
    Name = "fake-webserver-${count.index}"
  }
}
