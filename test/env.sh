#!/bin/sh

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    export TF_VAR_docker_host="${TF_VAR_docker_host:-npipe:////./pipe/docker_engine}"
    ;;
  *)
    export TF_VAR_docker_host="${TF_VAR_docker_host:-unix:///var/run/docker.sock}"
    ;;
esac
export TF_VAR_docker_network="home-portal-test"
export TF_VAR_timezone="America/Los_Angeles"

export TF_VAR_home_portal_image="${TF_VAR_home_portal_image:-home-portal:local}"
export TF_VAR_home_portal_container_name="home-portal-test"
export TF_VAR_home_portal_external_port="18099"
export TF_VAR_home_portal_db_host="postgres"
export TF_VAR_home_portal_db_port="5432"
export TF_VAR_home_portal_db_username="home_portal"
export TF_VAR_home_portal_db_password="local-test-only"
export TF_VAR_postgres_host="localhost"
export TF_VAR_postgres_port="55432"
export TF_VAR_postgres_root_user="postgres"
export TF_VAR_postgres_root_password="local-test-only"
export TF_VAR_s3_compatible_image="localstack/localstack:3.8.1"
export TF_VAR_s3_compatible_external_port="4566"

export TF_VAR_oauth2_enabled="false"
export TF_VAR_oauth2_admin='email("test@example.com")'
export TF_VAR_oauth2_issuer_url="http://localhost/test-issuer"
export TF_VAR_oauth2_auth_url="http://localhost/test-auth"
export TF_VAR_oauth2_token_url="http://localhost/test-token"
export TF_VAR_oauth2_client_id="home-portal-test"
export TF_VAR_oauth2_client_secret="local-test-only"
export TF_VAR_oauth2_client_scope=" "

export TF_VAR_backup_aws_image="amazon/aws-cli:2.18.9"
export TF_VAR_backup_s3_bucket="home-portal-test-backups"
export TF_VAR_backup_archive_name="home-portal-test-backup.zip"
export TF_VAR_backup_tmp_dir="../tmp"
export TF_VAR_backup_install_path="../bin"

export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_S3_ENDPOINT_URL="http://localstack:4566"
