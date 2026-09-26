terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "= 3.0.2"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "= 1.23.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "= 2.5.2"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

data "docker_network" "network" {
  name = var.docker_network
}

provider "postgresql" {
  host     = var.postgres_host
  port     = var.postgres_port
  username = var.postgres_root_username
  password = var.postgres_root_password
  sslmode  = "disable"
}
