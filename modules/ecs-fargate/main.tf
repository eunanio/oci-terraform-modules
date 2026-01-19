locals {
  cluster_name = var.create_cluster ? aws_ecs_cluster.this[0].name : var.cluster_name
  cluster_arn  = var.create_cluster ? aws_ecs_cluster.this[0].arn : data.aws_ecs_cluster.existing[0].arn
  
  task_execution_role_arn = var.create_task_execution_role ? aws_iam_role.task_execution[0].arn : var.task_execution_role_arn
  task_role_arn           = var.create_task_role ? aws_iam_role.task[0].arn : var.task_role_arn
  
  security_group_ids = var.create_security_group ? concat([aws_security_group.this[0].id], var.security_group_ids) : var.security_group_ids
  
  log_group_name = "/ecs/${var.name}"
  
  # Build container definitions with logging
  container_definitions = [
    for name, container in var.containers : merge(
      {
        name      = name
        image     = container.image
        essential = container.essential
        cpu       = container.cpu
        memory    = container.memory
        memoryReservation = container.memory_reservation
        
        portMappings = [
          for pm in container.port_mappings : {
            containerPort = pm.container_port
            hostPort      = pm.host_port != null ? pm.host_port : pm.container_port
            protocol      = pm.protocol
            name          = pm.name
          }
        ]
        
        environment = container.environment
        secrets     = container.secrets
        
        healthCheck = container.health_check
        
        command          = container.command
        entryPoint       = container.entryPoint
        workingDirectory = container.workingDirectory
        
        mountPoints = container.mount_points
        
        readonlyRootFilesystem = container.readonly_root_filesystem
        
        ulimits = container.ulimits
        
        linuxParameters = container.linux_parameters
        
        dependsOn = container.depends_on
        
        dockerLabels = container.docker_labels
        
        logConfiguration = container.log_configuration != null ? {
          logDriver = container.log_configuration.logDriver
          options = merge(
            container.log_configuration.logDriver == "awslogs" ? {
              "awslogs-group"         = local.log_group_name
              "awslogs-region"        = data.aws_region.current.name
              "awslogs-stream-prefix" = name
            } : {},
            container.log_configuration.options
          )
        } : {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = local.log_group_name
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = name
          }
        }
      }
    )
  ]
}

data "aws_region" "current" {}

data "aws_ecs_cluster" "existing" {
  count        = var.create_cluster ? 0 : 1
  cluster_name = var.cluster_name
}

# ECS Cluster
resource "aws_ecs_cluster" "this" {
  count = var.create_cluster ? 1 : 0

  name = var.name

  setting {
    name  = "containerInsights"
    value = var.cluster_settings.container_insights
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count = var.create_cluster ? 1 : 0

  cluster_name = aws_ecs_cluster.this[0].name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "this" {
  count = var.create_log_group ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, { Name = local.log_group_name })
}

# Task Execution Role
resource "aws_iam_role" "task_execution" {
  count = var.create_task_execution_role ? 1 : 0

  name = "${var.name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  count = var.create_task_execution_role ? 1 : 0

  role       = aws_iam_role.task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional permissions for Secrets Manager and SSM Parameter Store
resource "aws_iam_role_policy" "task_execution_secrets" {
  count = var.create_task_execution_role ? 1 : 0

  name = "${var.name}-task-execution-secrets"
  role = aws_iam_role.task_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

# Task Role
resource "aws_iam_role" "task" {
  count = var.create_task_role ? 1 : 0

  name = "${var.name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "task" {
  for_each = var.create_task_role ? toset(var.task_role_policies) : []

  role       = aws_iam_role.task[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "task_inline" {
  count = var.create_task_role && var.task_role_inline_policy != null ? 1 : 0

  name   = "${var.name}-task-inline-policy"
  role   = aws_iam_role.task[0].id
  policy = var.task_role_inline_policy
}

# ECS Exec permissions
resource "aws_iam_role_policy" "task_exec" {
  count = var.create_task_role && var.enable_execute_command ? 1 : 0

  name = "${var.name}-ecs-exec"
  role = aws_iam_role.task[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# Security Group
resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.name}-sg"
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-sg" })
}

resource "aws_security_group_rule" "ingress" {
  for_each = var.create_security_group ? {
    for idx, rule in var.security_group_rules.ingress : idx => rule
  } : {}

  type              = "ingress"
  security_group_id = aws_security_group.this[0].id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  source_security_group_id = length(each.value.security_groups) > 0 ? each.value.security_groups[0] : null
}

resource "aws_security_group_rule" "egress" {
  for_each = var.create_security_group ? {
    for idx, rule in var.security_group_rules.egress : idx => rule
  } : {}

  type              = "egress"
  security_group_id = aws_security_group.this[0].id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  source_security_group_id = length(each.value.security_groups) > 0 ? each.value.security_groups[0] : null
}

# Task Definition
resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = local.task_execution_role_arn
  task_role_arn            = local.task_role_arn

  container_definitions = jsonencode(local.container_definitions)

  runtime_platform {
    operating_system_family = var.runtime_platform.operating_system_family
    cpu_architecture        = var.runtime_platform.cpu_architecture
  }

  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.name

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_volume_configuration != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = efs_volume_configuration.value.root_directory
          transit_encryption      = efs_volume_configuration.value.transit_encryption
          transit_encryption_port = efs_volume_configuration.value.transit_encryption_port

          dynamic "authorization_config" {
            for_each = efs_volume_configuration.value.authorization_config != null ? [efs_volume_configuration.value.authorization_config] : []
            content {
              access_point_id = authorization_config.value.access_point_id
              iam             = authorization_config.value.iam
            }
          }
        }
      }
    }
  }

  tags = merge(var.tags, { Name = var.name })
}

# Service Discovery
resource "aws_service_discovery_service" "this" {
  count = var.service_discovery != null ? 1 : 0

  name = var.name

  dns_config {
    namespace_id = var.service_discovery.namespace_id

    dns_records {
      ttl  = var.service_discovery.dns_ttl
      type = var.service_discovery.dns_record_type
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = var.service_discovery.failure_threshold
  }

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = local.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  platform_version = var.platform_version

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  force_new_deployment              = var.force_new_deployment
  enable_execute_command            = var.enable_execute_command
  propagate_tags                    = var.propagate_tags

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = local.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  deployment_circuit_breaker {
    enable   = var.deployment_circuit_breaker.enable
    rollback = var.deployment_circuit_breaker.rollback
  }

  dynamic "load_balancer" {
    for_each = var.load_balancer != null ? [var.load_balancer] : []
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.service_discovery != null ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.this[0].arn
    }
  }

  tags = merge(var.tags, { Name = var.name })

  depends_on = [aws_cloudwatch_log_group.this]

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "this" {
  count = var.autoscaling != null ? 1 : 0

  max_capacity       = var.autoscaling.max_capacity
  min_capacity       = var.autoscaling.min_capacity
  resource_id        = "service/${local.cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "target_tracking" {
  for_each = var.autoscaling != null ? {
    for policy in var.autoscaling.target_tracking : policy.name => policy
  } : {}

  name               = each.key
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = each.value.target_value
    scale_in_cooldown  = each.value.scale_in_cooldown
    scale_out_cooldown = each.value.scale_out_cooldown
    disable_scale_in   = each.value.disable_scale_in

    dynamic "predefined_metric_specification" {
      for_each = each.value.predefined_metric != null ? [1] : []
      content {
        predefined_metric_type = each.value.predefined_metric
      }
    }

    dynamic "customized_metric_specification" {
      for_each = each.value.custom_metric != null ? [each.value.custom_metric] : []
      content {
        metric_name = customized_metric_specification.value.metric_name
        namespace   = customized_metric_specification.value.namespace
        statistic   = customized_metric_specification.value.statistic

        dynamic "dimensions" {
          for_each = customized_metric_specification.value.dimensions
          content {
            name  = dimensions.key
            value = dimensions.value
          }
        }
      }
    }
  }
}

resource "aws_appautoscaling_scheduled_action" "this" {
  for_each = var.autoscaling != null ? {
    for action in var.autoscaling.scheduled : action.name => action
  } : {}

  name               = each.key
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  schedule           = each.value.schedule
  timezone           = each.value.timezone

  scalable_target_action {
    min_capacity = each.value.min_capacity
    max_capacity = each.value.max_capacity
  }
}

