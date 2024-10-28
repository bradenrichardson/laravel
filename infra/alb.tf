resource "aws_lb" "laravel" {
  name                       = "${var.app_name}-alb"
  internal                   = true
  load_balancer_type        = "application"
  security_groups           = [aws_security_group.alb.id]
  subnets                   = module.vpc.private_subnets
  drop_invalid_header_fields = true # Added to drop invalid headers

  tags = {
    Name        = "${var.app_name}-alb"
    Environment = var.environment
    Terraform   = "true"
  }
}


resource "aws_lb_listener" "laravel" {
  load_balancer_arn = aws_lb.laravel.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.acm_certificate_arn

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
  protocol    = "HTTP"  # Keep this as HTTP since internal communication is secured
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    interval           = 30
    protocol           = "HTTP"  # Internal health check can remain HTTP
    matcher            = "200"
    timeout            = 5
    path              = "/"
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.app_name}-tg"
    Environment = var.environment
    Terraform   = "true"
  }
}

# Get the hosted zone data
data "aws_route53_zone" "selected" {
  name = "margaretriver.rentals"
}

# Create Route53 record
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "margaretriver.rentals"  # or use "api.margaretriver.rentals" if you want a subdomain
  type    = "A"

  alias {
    name                   = aws_lb.laravel.dns_name  # Assuming your ALB resource is named 'main'
    zone_id                = aws_lb.laravel.zone_id
    evaluate_target_health = true
  }
}

# Optional: Add HTTP to HTTPS redirect
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.laravel.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}