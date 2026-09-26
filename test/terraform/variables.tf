variable "docker_host" {
  type    = string
  default = "unix:///var/run/docker.sock"
}

variable "docker_network" {
  type    = string
  default = "home-portal-test"
}

variable "timezone" {
  type    = string
  default = "America/Los_Angeles"
}

variable "postgres_image" {
  type    = string
  default = "postgres:17"
}

variable "postgres_root_username" {
  type    = string
  default = "postgres"
}

variable "postgres_root_password" {
  type      = string
  sensitive = true
  default   = "local-test-only"
}

variable "postgres_external_port" {
  type    = number
  default = 55432
}

variable "s3_compatible_image" {
  type    = string
  default = "localstack/localstack:3.8.1"
}

variable "s3_compatible_external_port" {
  type    = number
  default = 4566
}

variable "aws_cli_image" {
  type    = string
  default = "amazon/aws-cli:2.18.9"
}

variable "backup_s3_bucket" {
  type    = string
  default = "home-portal-test-backups"
}
