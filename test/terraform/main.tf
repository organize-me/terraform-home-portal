terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "= 3.0.2"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

resource "docker_network" "test" {
  name = var.docker_network
}

resource "docker_image" "postgres" {
  name         = var.postgres_image
  keep_locally = true
}

resource "docker_container" "postgres" {
  image        = docker_image.postgres.image_id
  name         = "home-portal-test-postgres"
  hostname     = "postgres"
  network_mode = "bridge"
  wait         = true

  env = [
    "TZ=${var.timezone}",
    "POSTGRES_USER=${var.postgres_root_user}",
    "POSTGRES_PASSWORD=${var.postgres_root_password}",
  ]

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${var.postgres_root_user}"]
    interval = "5s"
    timeout  = "3s"
    retries  = 12
  }

  ports {
    internal = 5432
    external = var.postgres_external_port
  }

  networks_advanced {
    name    = docker_network.test.name
    aliases = ["postgres"]
  }
}

resource "docker_image" "localstack" {
  name         = var.s3_compatible_image
  keep_locally = true
}

resource "docker_container" "localstack" {
  image        = docker_image.localstack.image_id
  name         = "home-portal-test-s3"
  hostname     = "localstack"
  network_mode = "bridge"
  wait         = true

  env = [
    "SERVICES=s3",
    "DEFAULT_REGION=us-east-1",
  ]

  healthcheck {
    test     = ["CMD", "curl", "-f", "http://localhost:4566/_localstack/health"]
    interval = "5s"
    timeout  = "3s"
    retries  = 12
  }

  ports {
    internal = 4566
    external = var.s3_compatible_external_port
  }

  networks_advanced {
    name    = docker_network.test.name
    aliases = ["localstack"]
  }
}

resource "docker_image" "aws_cli" {
  name         = var.aws_cli_image
  keep_locally = true
}

resource "null_resource" "create_backup_bucket" {
  triggers = {
    localstack_id = docker_container.localstack.id
    bucket        = var.backup_s3_bucket
  }

  provisioner "local-exec" {
    command = "docker run --rm --network ${docker_network.test.name} --env AWS_ACCESS_KEY_ID=test --env AWS_SECRET_ACCESS_KEY=test --env AWS_DEFAULT_REGION=us-east-1 ${docker_image.aws_cli.name} s3 mb --endpoint-url http://localstack:4566 s3://${var.backup_s3_bucket}"
  }
}
