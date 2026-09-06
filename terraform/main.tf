
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
  availability_zone = data.aws_availability_zones.available.names[1]
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











resource "aws_security_group" "ALB_web_sg"{
    vpc_id = aws_vpc.main.id
    name = "web_sg"
    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }   
    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
}
}
resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.ALB_web_sg.id
  from_port         = 443
  to_port           = 443
  ip_protocol = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}







resource aws_lb_target_group "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ALB_web_sg.id]
  subnets            = [aws_subnet.public_A.id, aws_subnet.public_B.id]
}









resource aws_security_group "instance_sg" {
  name        = "instance_sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.ALB_web_sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.ALB_web_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "web_launch_template" { 
  name_prefix   = "web-launch-template-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance_sg.id] 
  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Welcome to the @Hmedd1 Highly Available Secure Web Platform</h1>" | sudo tee /var/www/html/index.html
              EOF
  )
}
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  vpc_zone_identifier  = [aws_subnet.private_A.id, aws_subnet.private_B.id]
  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.web_tg.arn]
}