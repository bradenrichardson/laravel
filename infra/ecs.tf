module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.11.4"

  cluster_name = "${var.app_name}-cluster"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/${var.app_name}"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 1
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  # Task execution IAM role
  create_task_exec_iam_role = true
  create_task_exec_policy  = true

  services = {
    laravel-app = {
      name = "${var.app_name}-service"
      
      # Task Definition
      cpu    = 256
      memory = 512

      # Deployment configuration
      deployment_minimum_healthy_percent = 50
      deployment_maximum_percent = 200

      # Network Configuration
      subnet_ids = module.vpc.private_subnets
      network_mode = "awsvpc"

      # Container Definitions
      container_definitions = {
        laravel-app = {
          name      = "${var.app_name}-container"
          cpu       = 256
          memory    = 512
          essential = true
          image     = "${var.app_name}:latest"
          port_mappings = [
            {
              name          = "${var.app_name}-port"
              containerPort = 8000
              protocol      = "tcp"
              hostPort      = 8000
            }
          ]
          
          enable_cloudwatch_logging = true
          log_configuration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = "/aws/ecs/${var.app_name}"
              awslogs-region        = var.aws_region
              awslogs-stream-prefix = "ecs"
            }
          }
        }
      }

      load_balancer = {
        service = {
          target_group_arn = aws_lb_target_group.laravel.arn
          container_name   = "${var.app_name}-container"
          container_port   = 8000
        }
      }

      security_group_rules = {
        ingress_alb = {
          type                     = "ingress"
          from_port               = 8000
          to_port                 = 8000
          protocol                = "tcp"
          source_security_group_id = aws_security_group.alb.id
          description             = "Allow incoming traffic from ALB"
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }

      assign_public_ip = false
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Application = var.app_name
  }
}