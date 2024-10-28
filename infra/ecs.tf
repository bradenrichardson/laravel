# ecs.tf
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.11.4"

  cluster_name = "${var.app_name}-cluster"

  # Cluster settings
  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/${var.app_name}"
      }
    }
  }

  # CloudWatch Container Insights
  cluster_settings = [{
    name  = "containerInsights"
    value = "enabled"
  }]

  # Fargate Capacity Providers
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

  # Task execution IAM role policies
  task_exec_iam_role_policies = {
    AWSXRayDaemonWriteAccess = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  }

  # Additional task execution IAM statements for CloudWatch
  task_exec_iam_statements = {
    cloudwatch_logs = {
      effect = "Allow"
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = ["${aws_cloudwatch_log_group.ecs.arn}:*"]
    }
  }

  services = {
    laravel-app = {
      name = "${var.app_name}-service"
      
      # Task Definition
      cpu    = 256
      memory = 512
      
      # Deployment configuration
      deployment_minimum_healthy_percent = 50
      deployment_maximum_percent = 200
      deployment_circuit_breaker = {
        enable   = true
        rollback = true
      }

      # Network Configuration
      subnet_ids = module.vpc.private_subnets
      security_group_ids = [aws_security_group.ecs_tasks.id]
      network_mode = "awsvpc"

      # Container Definitions
      container_definitions = {
        laravel-app = {
          name      = "${var.app_name}-container"
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.app_name}:latest"
          essential = true
          
          # Resource allocation
          cpu       = 256
          memory    = 512
          memory_reservation = 256

          # Port mappings
          port_mappings = [
            {
              name          = "${var.app_name}-port"
              containerPort = 8000
              protocol      = "tcp"
              hostPort      = 8000
            }
          ]

          healthcheck = {
            command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
            interval    = 30
            timeout     = 5
            retries     = 3
            startPeriod = 60
        }
          
          # CloudWatch logging
          enable_cloudwatch_logging = true
          log_configuration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = aws_cloudwatch_log_group.ecs.name
              awslogs-region        = var.aws_region
              awslogs-stream-prefix = "ecs"
            }
          }

          # Environment configuration
          environment = [
            {
              name  = "APP_ENV"
              value = var.environment
            },
            {
              name  = "APP_DEBUG"
              value = "false"
            }
          ]

          # Mount points for persistent storage if needed
          mount_points = []

          # Linux parameters
          linux_parameters = {
            capabilities = {
              drop = ["ALL"]
            }
            shared_memory_size = 64
          }

          # Security configuration
          readonly_root_filesystem = true
          privileged              = false
          user                    = "1000:1000"
        }
      }

      # Load Balancer Integration
      load_balancer = {
        service = {
          target_group_arn = aws_lb_target_group.laravel.arn
          container_name   = "${var.app_name}-container"
          container_port   = 8000
        }
      }


      # Autoscaling configuration
      enable_autoscaling = true
      autoscaling_min_capacity = 2
      autoscaling_max_capacity = 4

      # Autoscaling policies
      autoscaling_policies = {
        cpu = {
          policy_type = "TargetTrackingScaling"
          target_tracking_scaling_policy_configuration = {
            predefined_metric_specification = {
              predefined_metric_type = "ECSServiceAverageCPUUtilization"
            }
            target_value = 70.0
          }
        }
        memory = {
          policy_type = "TargetTrackingScaling"
          target_tracking_scaling_policy_configuration = {
            predefined_metric_specification = {
              predefined_metric_type = "ECSServiceAverageMemoryUtilization"
            }
            target_value = 80.0
          }
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

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/aws/ecs/${var.app_name}"
  retention_in_days = 30
  
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Application = var.app_name
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "${var.app_name}-cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = "85"
  alarm_description  = "CPU utilization has exceeded 85%"
  alarm_actions      = []  # Add SNS topic ARN if needed

  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = "${var.app_name}-service"
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Application = var.app_name
  }
}

resource "aws_cloudwatch_metric_alarm" "service_memory_high" {
  alarm_name          = "${var.app_name}-memory-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "MemoryUtilization"
  namespace          = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = "85"
  alarm_description  = "Memory utilization has exceeded 85%"
  alarm_actions      = []  # Add SNS topic ARN if needed

  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = "${var.app_name}-service"
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Application = var.app_name
  }
}

data "aws_caller_identity" "current" {}

# Add IAM policy to allow ECS to pull from ECR
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_ecr" {
  role       = module.ecs.task_exec_iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Add ECR permissions to task execution role
resource "aws_iam_role_policy" "ecs_task_execution_ecr" {
  name = "${var.app_name}-ecr-policy"
  role = module.ecs.task_exec_iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Outputs
output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = "${var.app_name}-service"
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.name
}