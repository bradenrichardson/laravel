module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "2.2.2"

  name          = "${var.app_name}-http-api"
  description   = "HTTP API Gateway for Laravel application"
  protocol_type = "HTTP"

  create_api_domain_name = false

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
    }

    "ANY /" = {
      connection_type    = "VPC_LINK"
      vpc_link          = "laravel"
      integration_type  = "HTTP_PROXY"
      integration_method = "ANY"
      integration_uri   = aws_lb_listener.laravel.arn
      payload_format_version = "1.0"
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