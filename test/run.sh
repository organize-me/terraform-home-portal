#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/test/env.sh"

APP_TF_DIR=""
APP_TF_INITIALIZED=0
TEST_TF_INITIALIZED=0

cleanup() {
  status=$?
  trap - EXIT

  if [ "$APP_TF_INITIALIZED" -eq 1 ]; then
    terraform -chdir="$APP_TF_DIR" destroy -auto-approve || status=1
  fi
  if [ "$TEST_TF_INITIALIZED" -eq 1 ]; then
    terraform -chdir="$ROOT_DIR/test/terraform" destroy -auto-approve || status=1
  fi
  if [ -n "$APP_TF_DIR" ]; then
    rm -rf -- "$APP_TF_DIR"
  fi

  exit "$status"
}
trap cleanup EXIT

for command in docker terraform curl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command not found: $command" >&2
    exit 1
  fi
done

docker info >/dev/null
if ! docker image inspect "$TF_VAR_home_portal_image" >/dev/null 2>&1; then
  echo "Home Portal image not found locally: $TF_VAR_home_portal_image" >&2
  echo "Build it from https://github.com/iv-host/home-portal before running this test." >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/test/bin" "$ROOT_DIR/test/tmp"

terraform -chdir="$ROOT_DIR/test/terraform" init
TEST_TF_INITIALIZED=1
terraform -chdir="$ROOT_DIR/test/terraform" apply -auto-approve

APP_TF_DIR="$(mktemp -d "$ROOT_DIR/test/app.XXXXXX")"
cp -R "$ROOT_DIR/terraform/." "$APP_TF_DIR/"
terraform -chdir="$APP_TF_DIR" init
APP_TF_INITIALIZED=1
terraform -chdir="$APP_TF_DIR" apply -auto-approve

for attempt in $(seq 1 60); do
  if curl --fail --silent http://localhost:18099/health-check >/dev/null; then
    break
  fi
  if [ "$attempt" -eq 60 ]; then
    echo "Home Portal did not become healthy" >&2
    exit 1
  fi
  sleep 2
done

APP_URL="http://localhost:18099"
TEST_LINK_NAME="backup-restore-test"
TEST_LINK_URL="https://example.invalid/backup-restore-test"

curl --fail --silent --show-error \
  --form "href=$TEST_LINK_URL" \
  "$APP_URL/api/links/$TEST_LINK_NAME" >/dev/null
if ! curl --fail --silent --show-error "$APP_URL/api/links" | grep -Fq "$TEST_LINK_URL"; then
  echo "Could not create the backup test link" >&2
  exit 1
fi

"$ROOT_DIR/test/bin/home-portal-backup.sh"
if [ -e "$ROOT_DIR/test/tmp/$TF_VAR_backup_archive_name" ]; then
  echo "Backup script left a temporary host archive behind" >&2
  exit 1
fi

docker run --rm \
  --network "$TF_VAR_docker_network" \
  --env "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" \
  --env "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" \
  --env "AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" \
  "$TF_VAR_backup_aws_image" \
  s3api head-object \
  --endpoint-url "$AWS_S3_ENDPOINT_URL" \
  --bucket "$TF_VAR_backup_s3_bucket" \
  --key "$TF_VAR_backup_archive_name"

curl --fail --silent --show-error \
  --request DELETE \
  "$APP_URL/api/links/$TEST_LINK_NAME" >/dev/null
if curl --fail --silent --show-error "$APP_URL/api/links" | grep -Fq "$TEST_LINK_URL"; then
  echo "Could not remove the backup test link before restore" >&2
  exit 1
fi

"$ROOT_DIR/test/bin/home-portal-restore.sh"
if [ -e "$ROOT_DIR/test/tmp/$TF_VAR_backup_archive_name" ]; then
  echo "Restore script left a temporary host archive behind" >&2
  exit 1
fi
curl --fail --silent --show-error "$APP_URL/health-check" >/dev/null
if ! curl --fail --silent --show-error "$APP_URL/api/links" | grep -Fq "$TEST_LINK_URL"; then
  echo "Restore did not recover the backed-up test link" >&2
  exit 1
fi
echo "Local Home Portal backup/restore test passed"
