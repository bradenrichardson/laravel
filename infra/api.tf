module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "2.2.2"

  name          = "${var.app_name}-http-api"
  description   = "HTTP API Gateway for Laravel application"
  protocol_type = "HTTP"

  create_api_domain_name = true
  domain_name           = "margaretriver.rentals"
  domain_name_certificate_arn = var.acm_certificate_arn

  # Enable access logging
  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.api_gateway.arn
  default_stage_access_log_format = jsonencode({
    requestId      = "$context.requestId"
    ip            = "$context.identity.sourceIp"
    requestTime    = "$context.requestTime"
    httpMethod     = "$context.httpMethod"
    routeKey       = "$context.routeKey"
    status         = "$context.status"
    protocol       = "$context.protocol"
    responseLength = "$context.responseLength"
    error         = "$context.error.message"
    integrationError = "$context.integration.error"
  })

  vpc_links = {
    laravel = {
      name               = "${var.app_name}-vpc-link"
      security_group_ids = [aws_security_group.vpc_link.id]
      subnet_ids         = module.vpc.private_subnets
    }
  }

  integrations = {
    "ANY /{proxy+}" = {
      connection_type    = "VPC_LINK"
      vpc_link          = "laravel"
      integration_type  = "HTTP_PROXY"
      integration_method = "ANY"
      integration_uri   = "https://${aws_lb.laravel.dns_name}:443/{proxy}"
      integration_uri_credentials_arn = null
      payload_format_version = "1.0"
      timeout_milliseconds = 29000
      tls_config = {
        server_name_to_verify = aws_lb.laravel.dns_name
      }
    }

    "ANY /" = {
      connection_type    = "VPC_LINK"
      vpc_link          = "laravel"
      integration_type  = "HTTP_PROXY"
      integration_method = "ANY"
      integration_uri   = "https://${aws_lb.laravel.dns_name}:443"
      integration_uri_credentials_arn = null
      payload_format_version = "1.0"
      timeout_milliseconds = 29000
      tls_config = {
        server_name_to_verify = aws_lb.laravel.dns_name
      }
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Application = var.app_name
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/api-gateway/${var.app_name}"
  retention_in_days = 30
  
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Application = var.app_name
  }
}

# Security group rules for VPC Link and ALB
resource "aws_security_group_rule" "vpc_link_to_alb" {
  security_group_id = aws_security_group.vpc_link.id
  type             = "egress"
  from_port        = 443
  to_port          = 443
  protocol         = "tcp"
  cidr_blocks      = [module.vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "alb_from_vpc_link" {
  security_group_id = aws_security_group.alb.id
  type             = "ingress"
  from_port        = 443
  to_port          = 443
  protocol         = "tcp"
  source_security_group_id = aws_security_group.vpc_link.id
}

# Additional security group rule for ALB to ECS tasks
resource "aws_security_group_rule" "alb_to_ecs" {
  security_group_id = aws_security_group.ecs_tasks.id
  type             = "ingress"
  from_port        = 8000
  to_port          = 8000
  protocol         = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

data "aws_route53_zone" "selected" {
  name = "margaretriver.rentals"
}

# Create Route53 record
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "margaretriver.rentals"
  type    = "A"

  alias {
    name                   = module.api_gateway.apigatewayv2_domain_name_target_domain_name
    zone_id                = module.api_gateway.apigatewayv2_domain_name_hosted_zone_id
    evaluate_target_health = true
  }
}