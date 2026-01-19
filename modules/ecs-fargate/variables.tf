# Service Name
variable "name" {
  description = "Name of the ECS service"
  type        = string
}

# Cluster Configuration
variable "cluster_name" {
  description = "Name of existing ECS cluster to use"
  type        = string
  default     = null
}

variable "create_cluster" {
  description = "Whether to create an ECS cluster"
  type        = bool
  default     = true
}

variable "cluster_settings" {
  description = "Cluster settings for Container Insights"
  type = object({
    container_insights = optional(string, "enabled")
  })
  default = {}
}

# Task Definition
variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory in MB for the task"
  type        = number
  default     = 512
}

variable "task_execution_role_arn" {
  description = "ARN of existing task execution role"
  type        = string
  default     = null
}

variable "create_task_execution_role" {
  description = "Whether to create a task execution role"
  type        = bool
  default     = true
}

variable "task_role_arn" {
  description = "ARN of existing task role"
  type        = string
  default     = null
}

variable "create_task_role" {
  description = "Whether to create a task role"
  type        = bool
  default     = true
}

variable "task_role_policies" {
  description = "List of IAM policy ARNs to attach to the task role"
  type        = list(string)
  default     = []
}

variable "task_role_inline_policy" {
  description = "Inline policy document for the task role"
  type        = string
  default     = null
}

variable "runtime_platform" {
  description = "Runtime platform for the task"
  type = object({
    operating_system_family = optional(string, "LINUX")
    cpu_architecture        = optional(string, "X86_64")
  })
  default = {}
}

# Container Definitions
variable "containers" {
  description = "Map of container definitions"
  type = map(object({
    image     = string
    essential = optional(bool, true)
    cpu       = optional(number)
    memory    = optional(number)
    memory_reservation = optional(number)
    
    port_mappings = optional(list(object({
      container_port = number
      host_port      = optional(number)
      protocol       = optional(string, "tcp")
      name           = optional(string)
    })), [])
    
    environment = optional(list(object({
      name  = string
      value = string
    })), [])
    
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })), [])
    
    health_check = optional(object({
      command     = list(string)
      interval    = optional(number, 30)
      timeout     = optional(number, 5)
      retries     = optional(number, 3)
      startPeriod = optional(number, 0)
    }))
    
    command    = optional(list(string))
    entryPoint = optional(list(string))
    workingDirectory = optional(string)
    
    log_configuration = optional(object({
      logDriver = optional(string, "awslogs")
      options   = optional(map(string), {})
    }))
    
    mount_points = optional(list(object({
      sourceVolume  = string
      containerPath = string
      readOnly      = optional(bool, false)
    })), [])
    
    readonly_root_filesystem = optional(bool, false)
    
    ulimits = optional(list(object({
      name      = string
      hardLimit = number
      softLimit = number
    })), [])
    
    linux_parameters = optional(object({
      initProcessEnabled = optional(bool, false)
      capabilities = optional(object({
        add  = optional(list(string), [])
        drop = optional(list(string), [])
      }))
    }))
    
    depends_on = optional(list(object({
      containerName = string
      condition     = string
    })), [])
    
    docker_labels = optional(map(string), {})
  }))
}

# Volumes
variable "volumes" {
  description = "Task definition volumes"
  type = list(object({
    name = string
    efs_volume_configuration = optional(object({
      file_system_id          = string
      root_directory          = optional(string, "/")
      transit_encryption      = optional(string, "ENABLED")
      transit_encryption_port = optional(number)
      authorization_config = optional(object({
        access_point_id = optional(string)
        iam             = optional(string, "DISABLED")
      }))
    }))
  }))
  default = []
}

# Service Configuration
variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent during deployment"
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Maximum percent during deployment"
  type        = number
  default     = 200
}

variable "force_new_deployment" {
  description = "Force new deployment on service update"
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for the service"
  type        = bool
  default     = false
}

# Deployment Circuit Breaker
variable "deployment_circuit_breaker" {
  description = "Deployment circuit breaker configuration"
  type = object({
    enable   = optional(bool, true)
    rollback = optional(bool, true)
  })
  default = {}
}

# Network Configuration
variable "subnet_ids" {
  description = "Subnet IDs for the service"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the service"
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Whether to create a security group"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
  default     = null
}

variable "security_group_rules" {
  description = "Security group rules"
  type = object({
    ingress = optional(list(object({
      description      = optional(string)
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string), [])
      security_groups  = optional(list(string), [])
    })), [])
    egress = optional(list(object({
      description      = optional(string)
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string), [])
      security_groups  = optional(list(string), [])
    })), [])
  })
  default = {
    egress = [{
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }]
  }
}

variable "assign_public_ip" {
  description = "Assign public IP to the task"
  type        = bool
  default     = false
}

# Load Balancer
variable "load_balancer" {
  description = "Load balancer configuration"
  type = object({
    target_group_arn = string
    container_name   = string
    container_port   = number
  })
  default = null
}

# Service Discovery
variable "service_discovery" {
  description = "Service discovery configuration"
  type = object({
    namespace_id   = string
    dns_record_type = optional(string, "A")
    dns_ttl        = optional(number, 60)
    failure_threshold = optional(number, 1)
  })
  default = null
}

# Auto Scaling
variable "autoscaling" {
  description = "Auto scaling configuration"
  type = object({
    min_capacity = optional(number, 1)
    max_capacity = optional(number, 10)
    
    target_tracking = optional(list(object({
      name               = string
      target_value       = number
      predefined_metric  = optional(string)
      custom_metric = optional(object({
        metric_name = string
        namespace   = string
        statistic   = string
        dimensions  = optional(map(string), {})
      }))
      scale_in_cooldown  = optional(number, 300)
      scale_out_cooldown = optional(number, 300)
      disable_scale_in   = optional(bool, false)
    })), [])
    
    scheduled = optional(list(object({
      name         = string
      schedule     = string
      min_capacity = optional(number)
      max_capacity = optional(number)
      timezone     = optional(string, "UTC")
    })), [])
  })
  default = null
}

# CloudWatch Logging
variable "create_log_group" {
  description = "Whether to create a CloudWatch log group"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# Platform Version
variable "platform_version" {
  description = "Fargate platform version"
  type        = string
  default     = "LATEST"
}

# Propagate Tags
variable "propagate_tags" {
  description = "Propagate tags from task definition or service"
  type        = string
  default     = "SERVICE"
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

