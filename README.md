# terraform-home-portal

Terraform configuration for deploying [Home Portal](https://github.com/iv-host/home-portal)
with PostgreSQL.

## Requirements

- Terraform
- Docker Engine and an existing Docker network
- An existing PostgreSQL server reachable both by Terraform and by containers on that network
- A built Home Portal Docker image

Terraform creates a database and login role named by `home_portal_db_username`, and grants
the role `CREATE` and `USAGE` on the database's `public` schema. It does not provision the
PostgreSQL server itself.

## Configure and apply

Run Terraform from the `terraform` directory. Supply values in a local, untracked
`terraform.tfvars` file, for example:

```hcl
docker_network          = "organize_me_network"
home_portal_image       = "home-portal:latest"
home_portal_db_host     = "postgres"
home_portal_db_username = "home_portal"
home_portal_db_password = "replace-me"
postgres_root_user      = "postgres"
postgres_root_password  = "replace-me"
backup_s3_bucket        = "my-home-portal-backups"
oauth2_admin            = "email(\"admin@example.com\")"
oauth2_client_secret    = "replace-me"
```

`postgres_host` defaults to `localhost` for Terraform's PostgreSQL provider. Set it to the
host that Terraform can use to reach PostgreSQL when that differs. Set
`home_portal_db_host` to the address the Home Portal container can use on the Docker network.
On Windows, set `docker_host` to `npipe:////./pipe/docker_engine`.
The Docker network defaults to `organize_me_network`, and the published application port
defaults to `8099`, matching the current container. OAuth2 is enabled by default; its issuer
and endpoint URLs and client ID default to the current application settings. Override these
variables as needed for another environment.

```sh
terraform init
terraform plan
terraform apply
```

The container receives `DATABASE_URL` (`jdbc:postgresql://<host>:<port>/<database>`),
`DATABASE_USERNAME`, and `DATABASE_PASSWORD`, plus the `OAUTH2_*` settings used by the
current application. It listens on port 8080 inside the container; Terraform publishes the
configured `home_portal_external_port` on the host.

## Backup and restore

Terraform writes executable `bin/home-portal-backup.sh` and
`bin/home-portal-restore.sh` scripts. Set `backup_s3_bucket` to the S3 bucket that stores
the archive. The scripts use the host's Docker CLI and AWS credentials; credentials can be
provided through the standard `~/.aws` files or AWS environment variables.

The backup script removes an existing archive in the container, creates a new ZIP archive
with the container's `home-portal backup` command, copies it to the host, uploads it to S3,
and removes the temporary host copy. The restore script downloads the archive from S3,
replaces the container's temporary archive, and runs `home-portal restore`. Restore replaces
the application's existing links, backgrounds, and images. PowerShell versions of both scripts
are generated for Windows hosts.

## Run the local integration test

The test runs PostgreSQL, LocalStack's S3-compatible service, and Home Portal in an isolated Docker network. It creates a
test link, backs it up, deletes it, and confirms restore recovers it from S3. It also checks the
app health endpoint and verifies temporary host backup files are removed. The test uses local-only
test credentials, creates a separate temporary copy of the Terraform configuration to avoid
using the main deployment's state, and destroys the test containers when it exits. Build the
local image in the Home Portal repository first:

```sh
docker build --file scripts/docker/Dockerfile --tag home-portal:local .
```

On Windows, Terraform and Docker Desktop are required; run the PowerShell test runner:

```powershell
.\test\run.ps1
```

On Linux or macOS, run:

```sh
bash test/run.sh
```

The test publishes PostgreSQL on port `55432`, LocalStack on `4566`, and Home Portal on
`18099`; choose different values in `test/env.sh` or `test/terraform/variables.tf` if those
ports are already in use.
