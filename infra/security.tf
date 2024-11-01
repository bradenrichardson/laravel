resource "aws_security_group" "vpc_link" {
  name        = "${var.app_name}-vpc-link"
  description = "Security group for API Gateway VPC Link"
  vpc_id      = module.vpc.vpc_id

  # Restrict ingress to only the VPC CIDR
  ingress {
    from_port   = 80 # Changed to HTTP port
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Allow incoming HTTP traffic from VPC"
  }

  # Restrict egress to only necessary services
  egress {
    from_port   = 80 # Changed to HTTP port
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Allow outbound HTTP traffic to ALB"
  }

  tags = {
    Name        = "${var.app_name}-vpc-link"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.app_name}-alb"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80 # Confirm HTTP port
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc_link.id]
    description     = "Allow incoming HTTP traffic from VPC Link"
  }

  egress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Allow outbound traffic to ECS tasks"
  }

  tags = {
    Name        = "${var.app_name}-alb"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-ecs-tasks"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow incoming traffic from ALB"
  }

  # Added additional egress rules for common services
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP outbound traffic for package installation"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound traffic for package installation and updates"
  }

  # Optional: Add if your application needs to connect to other AWS services
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Allow all outbound traffic within VPC"
  }

  tags = {
    Name        = "${var.app_name}-ecs-tasks"
    Environment = var.environment
    Terraform   = "true"
  }
}