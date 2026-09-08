provider "aws" {
  region = "eu-west-3"
}
data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block         = "10.0.0.0/16"
  enable_dns_support = true

  tags = {
    Name = "Highly-Available-Secure-Web-Platform"
  }
}

# -------------------------
# SUBNETS
# -------------------------

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

# -------------------------
# INTERNET GATEWAY
# -------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main Internet Gateway"
  }
}

# -------------------------
# PUBLIC ROUTE TABLE
# -------------------------

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

# -------------------------
# ALB SECURITY GROUP
# -------------------------

resource "aws_security_group" "ALB_web_sg" {
  vpc_id = aws_vpc.main.id
  name   = "web_sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# -------------------------
# LOAD BALANCER
# -------------------------

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.ALB_web_sg.id
  ]

  subnets = [
    aws_subnet.public_A.id,
    aws_subnet.public_B.id
  ]
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

# -------------------------
# EC2 SECURITY GROUP
# -------------------------

resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  description = "Allow HTTP traffic from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ALB_web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------
# LAUNCH TEMPLATE
# -------------------------

resource "aws_launch_template" "web_launch_template" {
  name_prefix   = "web-launch-template-"
  image_id      = data.aws_ssm_parameter.amazon_linux.value
  instance_type = "t3.micro"
  vpc_security_group_ids = [
    aws_security_group.instance_sg.id
  ]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo dnf update -y
              sudo dnf install -y httpd
              sudo systemctl enable --now httpd
              echo "<h1>Welcome to the @Hmedd1 Highly Available Secure Web Platform</h1>" | sudo tee /var/www/html/index.html
              EOF
  )
}

# -------------------------
# AUTO SCALING GROUP
# -------------------------

resource "aws_autoscaling_group" "web_asg" {
  desired_capacity = 2
  max_size         = 4
  min_size         = 2

  health_check_type         = "ELB"
  health_check_grace_period = 120

  vpc_zone_identifier = [
    aws_subnet.private_A.id,
    aws_subnet.private_B.id
  ]

  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = "$Latest"
  }

  target_group_arns = [
    aws_lb_target_group.web_tg.arn
  ]
}
# -------------------------
# NAT GATEWAY
# -------------------------

resource "aws_eip" "web_eip" {
  domain = "vpc"

  depends_on = [
    aws_internet_gateway.main
  ]
}

resource "aws_nat_gateway" "web_nat_gw" {
  allocation_id = aws_eip.web_eip.id
  subnet_id     = aws_subnet.public_A.id

  depends_on = [
    aws_internet_gateway.main
  ]
}

# -------------------------
# PRIVATE ROUTE TABLE
# -------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.web_nat_gw.id
  }
}

resource "aws_route_table_association" "private_A" {
  subnet_id      = aws_subnet.private_A.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_B" {
  subnet_id      = aws_subnet.private_B.id
  route_table_id = aws_route_table.private.id
}


# -------------------------
# DB
# -------------------------



resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Allow PostgreSQL  traffic from EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.instance_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.private_A.id, aws_subnet.private_B.id]

  tags = {
    Name = "DB Subnet Group"
  }
}


resource "aws_db_instance" "web_db" {
  identifier              = "web-db"
  engine                  = "postgres"
  db_name                 = "webapp"
  username                = "appadmin"
  port                    = 5432
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"
  max_allocated_storage   = 50
  publicly_accessible     = false
  storage_encrypted       = true
  multi_az                = true
  backup_retention_period = 1
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [
    aws_security_group.db_sg.id
  ]

  manage_master_user_password = true

  # Lab-friendly cleanup
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "Web Application Database"
  }
}





