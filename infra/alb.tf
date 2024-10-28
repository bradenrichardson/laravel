resource "aws_lb" "laravel" {
  name                       = "${var.app_name}-alb"
  internal                   = true
  load_balancer_type        = "application"
  security_groups           = [aws_security_group.alb.id]
  subnets                   = module.vpc.private_subnets
  drop_invalid_header_fields = true

  tags = {
    Name        = "${var.app_name}-alb"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_lb_listener" "laravel" {
  load_balancer_arn = aws_lb.laravel.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.laravel.arn
  }

  tags = {
    Name        = "${var.app_name}-listener"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_lb_target_group" "laravel" {
  name        = "${var.app_name}-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    interval           = 30
    protocol           = "HTTP"
    matcher            = "200"
    timeout            = 5
    path              = "/health"
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.app_name}-tg"
    Environment = var.environment
    Terraform   = "true"
  }
}
