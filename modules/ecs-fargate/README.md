# ECS Fargate Module

Creates an AWS ECS Fargate service with comprehensive configuration including task definitions, services, auto-scaling, load balancer integration, and service discovery.

## Features

- ECS cluster creation (optional)
- Task definitions with multiple containers
- Fargate service configuration
- Load balancer integration (ALB/NLB)
- Auto-scaling (target tracking and scheduled)
- Service discovery (Cloud Map)
- EFS volume mounts
- Secrets Manager and Parameter Store integration
- CloudWatch logging
- Deployment circuit breaker
- ECS Exec support

## Usage with Nori

```bash
nori release create my-service ghcr.io/eunanio/oci-terraform-modules/ecs-fargate:v1.0.0 -f values.yaml
```

## Usage with OpenTofu/Terraform

```hcl
module "ecs_service" {
  source = "oci://ghcr.io/eunanio/oci-terraform-modules/ecs-fargate?tag=v1.0.0"

  name = "my-api"

  task_cpu    = 512
  task_memory = 1024

  containers = {
    api = {
      image = "nginx:latest"
      port_mappings = [{
        container_port = 80
      }]
    }
  }

  subnet_ids         = ["subnet-abc123", "subnet-def456"]
  security_group_ids = ["sg-xyz789"]

  load_balancer = {
    target_group_arn = "arn:aws:elasticloadbalancing:..."
    container_name   = "api"
    container_port   = 80
  }

  tags = {
    Environment = "production"
  }
}
```

## Values File Example

```yaml
# values.yaml

# === Service Name ===
name: my-api-service

# === Cluster Configuration ===
# Create a new cluster or use existing
create_cluster: true
# cluster_name: existing-cluster  # If using existing cluster

cluster_settings:
  container_insights: enabled

# === Task Configuration ===
task_cpu: 1024     # CPU units (256, 512, 1024, 2048, 4096)
task_memory: 2048  # Memory in MB

runtime_platform:
  operating_system_family: LINUX
  cpu_architecture: ARM64  # or X86_64

# === IAM Roles ===
create_task_execution_role: true
create_task_role: true

# Additional policies for task role
task_role_policies:
  - arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
  - arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess

# Inline policy for task role
task_role_inline_policy: |
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["sqs:SendMessage", "sqs:ReceiveMessage"],
        "Resource": "arn:aws:sqs:*:*:my-queue"
      }
    ]
  }

# === Container Definitions ===
containers:
  # Main application container
  api:
    image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-api:latest
    essential: true
    cpu: 768
    memory: 1536
    
    port_mappings:
      - container_port: 8080
        protocol: tcp
        name: http
    
    environment:
      - name: NODE_ENV
        value: production
      - name: LOG_LEVEL
        value: info
    
    secrets:
      - name: DATABASE_URL
        valueFrom: arn:aws:secretsmanager:us-east-1:123456789012:secret:db-credentials:url::
      - name: API_KEY
        valueFrom: arn:aws:ssm:us-east-1:123456789012:parameter/my-app/api-key
    
    health_check:
      command:
        - CMD-SHELL
        - curl -f http://localhost:8080/health || exit 1
      interval: 30
      timeout: 5
      retries: 3
      startPeriod: 60
    
    mount_points:
      - sourceVolume: app-data
        containerPath: /data
        readOnly: false
    
    readonly_root_filesystem: true
    
    linux_parameters:
      initProcessEnabled: true
      capabilities:
        drop:
          - ALL
    
    docker_labels:
      com.example.app: my-api
      com.example.version: "1.0"

  # Sidecar container
  datadog-agent:
    image: public.ecr.aws/datadog/agent:latest
    essential: false
    cpu: 256
    memory: 512
    
    environment:
      - name: DD_APM_ENABLED
        value: "true"
      - name: ECS_FARGATE
        value: "true"
    
    secrets:
      - name: DD_API_KEY
        valueFrom: arn:aws:secretsmanager:us-east-1:123456789012:secret:datadog-api-key

# === Volumes ===
volumes:
  - name: app-data
    efs_volume_configuration:
      file_system_id: fs-abc123
      root_directory: /my-app
      transit_encryption: ENABLED
      authorization_config:
        access_point_id: fsap-abc123
        iam: ENABLED

# === Service Configuration ===
desired_count: 3
deployment_minimum_healthy_percent: 100
deployment_maximum_percent: 200
force_new_deployment: false
enable_execute_command: true  # Enable ECS Exec

deployment_circuit_breaker:
  enable: true
  rollback: true

# === Network Configuration ===
subnet_ids:
  - subnet-abc123
  - subnet-def456
  - subnet-ghi789

# Option 1: Use existing security groups
security_group_ids:
  - sg-abc123

# Option 2: Create security group
create_security_group: true
vpc_id: vpc-xyz789
security_group_rules:
  ingress:
    - description: ALB access
      from_port: 8080
      to_port: 8080
      protocol: tcp
      security_groups:
        - sg-alb123
  egress:
    - description: All outbound
      from_port: 0
      to_port: 0
      protocol: "-1"
      cidr_blocks:
        - 0.0.0.0/0

assign_public_ip: false

# === Load Balancer ===
load_balancer:
  target_group_arn: arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-tg/abc123
  container_name: api
  container_port: 8080

# === Service Discovery ===
service_discovery:
  namespace_id: ns-abc123
  dns_record_type: A
  dns_ttl: 60
  failure_threshold: 1

# === Auto Scaling ===
autoscaling:
  min_capacity: 2
  max_capacity: 20
  
  target_tracking:
    # CPU-based scaling
    - name: cpu-scaling
      target_value: 70
      predefined_metric: ECSServiceAverageCPUUtilization
      scale_in_cooldown: 300
      scale_out_cooldown: 60
    
    # Memory-based scaling
    - name: memory-scaling
      target_value: 80
      predefined_metric: ECSServiceAverageMemoryUtilization
      scale_in_cooldown: 300
      scale_out_cooldown: 60
    
    # Request count scaling (with ALB)
    - name: request-scaling
      target_value: 1000
      predefined_metric: ALBRequestCountPerTarget
      scale_in_cooldown: 300
      scale_out_cooldown: 60
  
  scheduled:
    # Scale up for business hours
    - name: scale-up-morning
      schedule: "cron(0 8 ? * MON-FRI *)"
      min_capacity: 5
      max_capacity: 20
      timezone: America/New_York
    
    # Scale down for off-hours
    - name: scale-down-evening
      schedule: "cron(0 20 ? * MON-FRI *)"
      min_capacity: 2
      max_capacity: 10
      timezone: America/New_York

# === CloudWatch Logging ===
create_log_group: true
log_retention_days: 30

# === Platform Version ===
platform_version: "1.4.0"  # or LATEST

# === Propagate Tags ===
propagate_tags: SERVICE

# === Tags ===
tags:
  Environment: production
  Application: my-api
  Team: platform
  CostCenter: "12345"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the ECS service | `string` | n/a | yes |
| containers | Map of container definitions | `map(object)` | n/a | yes |
| subnet_ids | Subnet IDs for the service | `list(string)` | n/a | yes |
| cluster_name | Name of existing ECS cluster | `string` | `null` | no |
| create_cluster | Whether to create an ECS cluster | `bool` | `true` | no |
| task_cpu | CPU units for the task | `number` | `256` | no |
| task_memory | Memory in MB for the task | `number` | `512` | no |
| create_task_execution_role | Create task execution role | `bool` | `true` | no |
| create_task_role | Create task role | `bool` | `true` | no |
| task_role_policies | IAM policy ARNs for task role | `list(string)` | `[]` | no |
| volumes | Task definition volumes | `list(object)` | `[]` | no |
| desired_count | Desired number of tasks | `number` | `1` | no |
| security_group_ids | Security group IDs | `list(string)` | `[]` | no |
| create_security_group | Create a security group | `bool` | `false` | no |
| load_balancer | Load balancer configuration | `object` | `null` | no |
| service_discovery | Service discovery configuration | `object` | `null` | no |
| autoscaling | Auto scaling configuration | `object` | `null` | no |
| enable_execute_command | Enable ECS Exec | `bool` | `false` | no |
| log_retention_days | CloudWatch log retention | `number` | `30` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the ECS cluster |
| cluster_arn | ARN of the ECS cluster |
| cluster_name | Name of the ECS cluster |
| task_definition_arn | ARN of the task definition |
| task_definition_family | Family of the task definition |
| task_definition_revision | Revision of the task definition |
| service_id | ID of the ECS service |
| service_name | Name of the ECS service |
| service_arn | ARN of the ECS service |
| task_execution_role_arn | ARN of the task execution role |
| task_execution_role_name | Name of the task execution role |
| task_role_arn | ARN of the task role |
| task_role_name | Name of the task role |
| security_group_id | ID of the created security group |
| log_group_name | Name of the CloudWatch log group |
| log_group_arn | ARN of the CloudWatch log group |
| service_discovery_arn | ARN of the service discovery service |
| autoscaling_target_id | ID of the auto scaling target |

