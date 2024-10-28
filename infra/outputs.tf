output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "api_gateway_endpoint" {
  description = "The HTTP API Gateway endpoint"
  value       = module.api_gateway.apigatewayv2_api_api_endpoint
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.laravel.dns_name
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs.cluster_name
}