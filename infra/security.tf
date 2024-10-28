resource "aws_security_group" "vpc_link" {
  name        = "${var.app_name}-vpc-link"
  description = "Security group for API Gateway VPC Link"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming traffic to VPC Link"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
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
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc_link.id]
    description     = "Allow incoming traffic from VPC Link"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.app_name}-alb"
    Environment = var.environment
    Terraform   = "true"
  }
}