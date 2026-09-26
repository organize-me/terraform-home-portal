resource "postgresql_database" "home_portal" {
  name  = var.home_portal_db_username
  owner = postgresql_role.home_portal.name
}

resource "postgresql_role" "home_portal" {
  name     = var.home_portal_db_username
  password = var.home_portal_db_password
  login    = true
}

resource "postgresql_grant" "home_portal" {
  role        = postgresql_role.home_portal.name
  database    = postgresql_database.home_portal.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["CREATE", "USAGE"]

  depends_on = [
    postgresql_database.home_portal,
    postgresql_role.home_portal,
  ]
}
