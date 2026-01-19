# Instance Identifier
variable "identifier" {
  description = "Identifier for the RDS instance"
  type        = string
}

# Engine Configuration
variable "engine" {
  description = "Database engine (mysql, postgres, mariadb, oracle-*, sqlserver-*)"
  type        = string
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class (e.g., db.t3.micro, db.r5.large)"
  type        = string
}

# Database Configuration
variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = null
}

variable "username" {
  description = "Master username for the database"
  type        = string
}

variable "password" {
  description = "Master password (if not set, a random password will be generated)"
  type        = string
  default     = null
  sensitive   = true
}

variable "port" {
  description = "Database port"
  type        = number
  default     = null
}

# Storage Configuration
variable "allocated_storage" {
  description = "Initial storage allocation in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling (0 to disable)"
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1, io2, magnetic)"
  type        = string
  default     = "gp3"
}

variable "iops" {
  description = "Provisioned IOPS (for io1, io2, gp3)"
  type        = number
  default     = null
}

variable "storage_throughput" {
  description = "Storage throughput in MiBps (for gp3)"
  type        = number
  default     = null
}

# Network Configuration
variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs"
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

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "allowed_security_groups" {
  description = "Security groups allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "publicly_accessible" {
  description = "Whether the instance is publicly accessible"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "Availability zone for the instance"
  type        = string
  default     = null
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

# Encryption
variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

# Backup Configuration
variable "backup_retention_period" {
  description = "Backup retention period in days (0 to disable)"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window (e.g., 03:00-04:00)"
  type        = string
  default     = null
}

variable "delete_automated_backups" {
  description = "Delete automated backups when instance is deleted"
  type        = bool
  default     = true
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to snapshots"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot before deletion"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Identifier for the final snapshot"
  type        = string
  default     = null
}

variable "snapshot_identifier" {
  description = "Snapshot ID to restore from"
  type        = string
  default     = null
}

# Maintenance
variable "maintenance_window" {
  description = "Preferred maintenance window (e.g., Mon:04:00-Mon:05:00)"
  type        = string
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "allow_major_version_upgrade" {
  description = "Allow major version upgrades"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during maintenance window"
  type        = bool
  default     = false
}

# Parameter and Option Groups
variable "parameter_group_name" {
  description = "Name of existing parameter group to use"
  type        = string
  default     = null
}

variable "create_parameter_group" {
  description = "Whether to create a parameter group"
  type        = bool
  default     = false
}

variable "parameter_group_family" {
  description = "DB parameter group family"
  type        = string
  default     = null
}

variable "parameters" {
  description = "List of DB parameters"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "option_group_name" {
  description = "Name of existing option group to use"
  type        = string
  default     = null
}

variable "create_option_group" {
  description = "Whether to create an option group"
  type        = bool
  default     = false
}

variable "major_engine_version" {
  description = "Major engine version for option group"
  type        = string
  default     = null
}

variable "options" {
  description = "List of DB options"
  type = list(object({
    option_name                    = string
    port                           = optional(number)
    version                        = optional(string)
    db_security_group_memberships  = optional(list(string))
    vpc_security_group_memberships = optional(list(string))
    option_settings = optional(list(object({
      name  = string
      value = string
    })), [])
  }))
  default = []
}

# Monitoring
variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "ARN of IAM role for enhanced monitoring"
  type        = string
  default     = null
}

variable "create_monitoring_role" {
  description = "Whether to create enhanced monitoring IAM role"
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "performance_insights_kms_key_id" {
  description = "KMS key ARN for Performance Insights encryption"
  type        = string
  default     = null
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = []
}

# Deletion Protection
variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

# IAM Authentication
variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = false
}

# Character Set (Oracle/SQL Server)
variable "character_set_name" {
  description = "Character set for Oracle/SQL Server"
  type        = string
  default     = null
}

# License Model
variable "license_model" {
  description = "License model (license-included, bring-your-own-license)"
  type        = string
  default     = null
}

# Domain (Active Directory)
variable "domain" {
  description = "Active Directory domain to join"
  type        = string
  default     = null
}

variable "domain_iam_role_name" {
  description = "IAM role name for Active Directory"
  type        = string
  default     = null
}

# Network Type
variable "network_type" {
  description = "Network type (IPV4 or DUAL)"
  type        = string
  default     = null
}

# CA Certificate
variable "ca_cert_identifier" {
  description = "CA certificate identifier"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

