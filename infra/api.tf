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

# api.tf
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
      integration_uri   = aws_lb_listener.laravel.arn
      payload_format_version = "1.0"
      timeout_milliseconds = 29000
      request_parameters = {
        "overwrite:path" = "$request.path"
      }
    }

    "ANY /" = {
      connection_type    = "VPC_LINK"
      vpc_link          = "laravel"
      integration_type  = "HTTP_PROXY"
      integration_method = "ANY"
      integration_uri   = aws_lb_listener.laravel.arn
      payload_format_version = "1.0"
      timeout_milliseconds = 29000
      request_parameters = {
        "overwrite:path" = "/"
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