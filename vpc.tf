terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my_vpc"
  }
}
resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "pub_sub"
  }
}
resource "aws_subnet" "prisub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "pri_sub"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "igw"
  }
}
resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "pub_rt"
  }
}
resource "aws_route_table_association" "pubrtasso" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id
}
resource "aws_eip" "teip" {
  vpc      = true
}
resource "aws_nat_gateway" "tnat" {
  allocation_id = aws_eip.teip.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "gw NAT"
  }
}
resource "aws_route_table" "prirt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "10.0.2.0/24"
    gateway_id = aws_nat_gateway.tnat.id
  }

  tags = {
    Name = "pri_rt"
  }
}
resource "aws_route_table_association" "prirtass" {
  subnet_id      = aws_subnet.prisub.id
  route_table_id = aws_route_table.prirt.id
}
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "all from VPC"
    from_port        = 22
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_all"
  }
}
resource "aws_instance" "instance1_public"{
      ami ="ami-0af25d0df86db00c1"
      associate_public_ip_address = true
      availability_zone = "ap-south-1a"
      key_name = "ATHUL"
      instance_type = "t2 micro"
      subnet_id = aws_subnet.pubsub.id
      vpc_security_group_ids = [aws_security_group.allow_all.id]
}
resource "aws_instance" "instance1_pri"{
      ami ="ami-0af25d0df86db00c1"
      associate_public_ip_address = false
      availability_zone = "ap-south-1b"
      key_name = "ATHUL"
      instance_type = "t2 micro"
      subnet_id = aws_subnet.prisub.id
      vpc_security_group_ids = [aws_security_group.allow_all.id]
}
