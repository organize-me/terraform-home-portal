resource "docker_image" "home_portal" {
  name         = var.home_portal_image
  keep_locally = true
}

resource "docker_container" "home_portal" {
  image        = docker_image.home_portal.image_id
  name         = var.home_portal_container_name
  hostname     = "home-portal"
  restart      = "unless-stopped"
  network_mode = "bridge"

  env = [
    "TZ=${var.timezone}",
    "DATABASE_URL=jdbc:postgresql://${var.home_portal_db_host}:${var.home_portal_db_port}/${postgresql_database.home_portal.name}",
    "DATABASE_USERNAME=${var.home_portal_db_username}",
    "DATABASE_PASSWORD=${var.home_portal_db_password}",
    "OAUTH2_ENABLED=${var.home_portal_oauth2_enabled}",
    "OAUTH2_ADMIN=${var.home_portal_oauth2_admin}",
    "OAUTH2_ISSUER_URL=${var.home_portal_oauth2_issuer_url}",
    "OAUTH2_AUTH_URL=${var.home_portal_oauth2_auth_url}",
    "OAUTH2_TOKEN_URL=${var.home_portal_oauth2_token_url}",
    "OAUTH2_CLIENT_ID=${var.home_portal_oauth2_client_id}",
    "OAUTH2_CLIENT_SECRET=${var.home_portal_oauth2_client_secret}",
    "OAUTH2_CLIENT_SCOPE=${var.home_portal_oauth2_client_scope}",
  ]

  ports {
    internal = 8080
    external = var.home_portal_external_port
  }

  networks_advanced {
    name    = data.docker_network.network.name
    aliases = ["home-portal"]
  }

  depends_on = [
    postgresql_database.home_portal,
    postgresql_role.home_portal,
    postgresql_grant.home_portal,
  ]
}
