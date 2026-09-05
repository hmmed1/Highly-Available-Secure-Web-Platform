
provider "aws" {
  region = "eu-west-3"
}
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  tags = {
    Name = "Highly-Available-Secure-Web-Platform"
  }
}
resource "aws_subnet" "public_A" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "Public Subnet A"
  }
  }
  resource "aws_subnet" "private_A" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "Private Subnet A"
  }
  }


resource "aws_subnet" "public_B" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "Public Subnet B"
  }
  }
resource "aws_subnet" "private_B" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  tags = {
    Name = "Private Subnet B"
  }
  }

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Main Internet Gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
resource "aws_route_table_association" "public_A" {
  subnet_id      = aws_subnet.public_A.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_B" {
  subnet_id      = aws_subnet.public_B.id
  route_table_id = aws_route_table.public.id
}
resource "aws_security_group" "web_sg"{
    vpc_id = aws_vpc.main.id
    name = "web_sg"
    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }   
}