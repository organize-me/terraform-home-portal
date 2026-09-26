resource "local_file" "backup_script" {
  filename        = "${var.backup_install_path}/home-portal-backup.sh"
  file_permission = "0755"
  content = templatefile("./backup/backup.sh.tftpl", {
    TF_ARCHIVE_NAME          = var.backup_archive_name
    TF_S3_BACKUP_BUCKET      = var.backup_s3_bucket
    TF_AWS_CLI_IMAGE         = var.backup_aws_image
    TF_BACKUP_TMP_DIR        = abspath(var.backup_tmp_dir)
    TF_DOCKER_NETWORK        = var.docker_network
    TF_HOME_PORTAL_CONTAINER = docker_container.home_portal.name
  })
}

resource "local_file" "restore_script" {
  filename        = "${var.backup_install_path}/home-portal-restore.sh"
  file_permission = "0755"
  content = templatefile("./backup/restore.sh.tftpl", {
    TF_ARCHIVE_NAME          = var.backup_archive_name
    TF_S3_BACKUP_BUCKET      = var.backup_s3_bucket
    TF_AWS_CLI_IMAGE         = var.backup_aws_image
    TF_BACKUP_TMP_DIR        = abspath(var.backup_tmp_dir)
    TF_DOCKER_NETWORK        = var.docker_network
    TF_HOME_PORTAL_CONTAINER = docker_container.home_portal.name
  })
}

resource "local_file" "backup_powershell_script" {
  filename = "${var.backup_install_path}/home-portal-backup.ps1"
  content = templatefile("./backup/backup.ps1.tftpl", {
    TF_ARCHIVE_NAME          = var.backup_archive_name
    TF_S3_BACKUP_BUCKET      = var.backup_s3_bucket
    TF_AWS_CLI_IMAGE         = var.backup_aws_image
    TF_BACKUP_TMP_DIR        = abspath(var.backup_tmp_dir)
    TF_DOCKER_NETWORK        = var.docker_network
    TF_HOME_PORTAL_CONTAINER = docker_container.home_portal.name
  })
}

resource "local_file" "restore_powershell_script" {
  filename = "${var.backup_install_path}/home-portal-restore.ps1"
  content = templatefile("./backup/restore.ps1.tftpl", {
    TF_ARCHIVE_NAME          = var.backup_archive_name
    TF_S3_BACKUP_BUCKET      = var.backup_s3_bucket
    TF_AWS_CLI_IMAGE         = var.backup_aws_image
    TF_BACKUP_TMP_DIR        = abspath(var.backup_tmp_dir)
    TF_DOCKER_NETWORK        = var.docker_network
    TF_HOME_PORTAL_CONTAINER = docker_container.home_portal.name
  })
}
