module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "2.2.2"

  name          = "${var.app_name}-http-api"
  description   = "HTTP API Gateway for Laravel application"
  protocol_type = "HTTP"

  create_api_domain_name = false

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