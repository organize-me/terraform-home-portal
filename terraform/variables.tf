variable "timezone" {
  type    = string
  default = "America/Los_Angeles"
}

variable "docker_host" {
  type    = string
  default = "unix:///var/run/docker.sock"
}

variable "docker_network" {
  type    = string
  default = "organize_me_network"
}

variable "home_portal_image" {
  description = "The Home Portal Docker image to run"
  type        = string
  default     = "home-portal:latest"
}

variable "home_portal_container_name" {
  description = "The Docker container name for Home Portal"
  type        = string
  default     = "organize-me-home-portal"
}

variable "home_portal_external_port" {
  description = "The host port published for Home Portal"
  type        = number
  default     = 8099
}

variable "home_portal_db_host" {
  description = "The PostgreSQL host reachable from the Home Portal container"
  type        = string
}

variable "home_portal_db_port" {
  description = "The PostgreSQL port reachable from the Home Portal container"
  type        = number
  default     = 5432
}

variable "home_portal_db_username" {
  description = "The PostgreSQL role and database name for Home Portal"
  type        = string
}

variable "home_portal_db_password" {
  description = "The PostgreSQL password for Home Portal"
  type        = string
  sensitive   = true
}

variable "postgres_root_username" {
  description = "The PostgreSQL administrator username used by Terraform"
  type        = string
}

variable "postgres_root_password" {
  description = "The PostgreSQL administrator password used by Terraform"
  type        = string
  sensitive   = true
}

variable "postgres_host" {
  description = "The PostgreSQL host reachable from Terraform"
  type        = string
  default     = "localhost"
}

variable "postgres_port" {
  description = "The PostgreSQL port reachable from Terraform"
  type        = number
  default     = 5432
}

variable "home_portal_oauth2_enabled" {
  description = "Whether to enable OAuth2 authentication in Home Portal"
  type        = bool
  default     = true
}

variable "home_portal_oauth2_admin" {
  description = "The Home Portal OAuth2 administrator expression (for example, email(\"admin@example.com\"))"
  type        = string
}

variable "home_portal_oauth2_issuer_url" {
  description = "The OAuth2 issuer URL"
  type        = string
  default     = "https://auth.vanderelst.house/auth/realms/home"
}

variable "home_portal_oauth2_auth_url" {
  description = "The OAuth2 authorization endpoint URL"
  type        = string
  default     = "https://auth.vanderelst.house/auth/realms/home/protocol/openid-connect/auth"
}

variable "home_portal_oauth2_token_url" {
  description = "The OAuth2 token endpoint URL"
  type        = string
  default     = "https://auth.vanderelst.house/auth/realms/home/protocol/openid-connect/token"
}

variable "home_portal_oauth2_client_id" {
  description = "The OAuth2 client ID"
  type        = string
  default     = "home-portal"
}

variable "home_portal_oauth2_client_secret" {
  description = "The OAuth2 client secret"
  type        = string
  sensitive   = true
}

variable "home_portal_oauth2_client_scope" {
  description = "Optional OAuth2 client scope"
  type        = string
  default     = " "
}

variable "backup_aws_image" {
  description = "The AWS CLI Docker image used to transfer backups"
  type        = string
  default     = "amazon/aws-cli:2.18.9"
}

variable "backup_install_path" {
  description = "The directory where Terraform writes the backup and restore scripts"
  type        = string
  default     = "../bin"
}

variable "backup_archive_name" {
  description = "The backup archive filename used on the host and in S3"
  type        = string
  default     = "home-portal-backup.zip"

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.backup_archive_name))
    error_message = "backup_archive_name must be a simple filename containing only letters, numbers, dots, underscores, and hyphens."
  }
}

variable "backup_s3_bucket" {
  description = "The S3 bucket where Home Portal backup archives are stored"
  type        = string
}

variable "backup_tmp_dir" {
  description = "The host temporary directory used during backup and restore"
  type        = string
  default     = "../tmp"
}
