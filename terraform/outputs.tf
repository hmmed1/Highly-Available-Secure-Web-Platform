output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value = [
    aws_subnet.public_A.id,
    aws_subnet.public_B.id
  ]
}

output "private_subnet_ids" {
  description = "IDs of the private application subnets"
  value = [
    aws_subnet.private_A.id,
    aws_subnet.private_B.id
  ]
}

output "availability_zones" {
  description = "Availability Zones used by the platform"
  value = [
    aws_subnet.public_A.availability_zone,
    aws_subnet.public_B.availability_zone
  ]
}

output "alb_dns_name" {
  description = "DNS name of the public Application Load Balancer"
  value       = aws_lb.web_alb.dns_name
}

output "application_url" {
  description = "HTTP URL used to access the application"
  value       = "http://${aws_lb.web_alb.dns_name}"
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.web_tg.arn
}

output "autoscaling_group_name" {
  description = "Name of the web Auto Scaling Group"
  value       = aws_autoscaling_group.web_asg.name
}

output "autoscaling_min_size" {
  description = "Minimum number of web instances"
  value       = aws_autoscaling_group.web_asg.min_size
}

output "autoscaling_desired_capacity" {
  description = "Desired number of web instances"
  value       = aws_autoscaling_group.web_asg.desired_capacity
}

output "autoscaling_max_size" {
  description = "Maximum number of web instances"
  value       = aws_autoscaling_group.web_asg.max_size
}

output "rds_endpoint" {
  description = "Private endpoint of the PostgreSQL database"
  value       = aws_db_instance.web_db.address
}

output "rds_port" {
  description = "PostgreSQL database port"
  value       = aws_db_instance.web_db.port
}

output "rds_multi_az" {
  description = "Whether the database uses Multi-AZ deployment"
  value       = aws_db_instance.web_db.multi_az
}

output "nat_gateway_public_ip" {
  description = "Public IP used by the NAT Gateway for outbound traffic"
  value       = aws_eip.web_eip.public_ip
}

output "developer_role_arn" {
  description = "ARN of the developer IAM role"
  value       = aws_iam_role.developer_role.arn
}

output "sysadmin_role_arn" {
  description = "ARN of the sysadmin IAM role"
  value       = aws_iam_role.sysadmin_role.arn
}