param(
    # Start the test environment and leave it running for manual testing.
    [switch] $Up,
    # Tear down an environment started with -Up.
    [switch] $Down
)

$ErrorActionPreference = "Stop"

$RootDirectory = Split-Path -Parent $PSScriptRoot
$TestTerraformDirectory = Join-Path $PSScriptRoot "terraform"
$TerraformExecutable = (Get-Command terraform -ErrorAction Stop).Source
$CurlExecutable = (Get-Command curl.exe -ErrorAction Stop).Source
$RunId = if ($Up -or $Down) { "manual" } else { [Guid]::NewGuid().ToString("N") }
$KeepResources = $false
$AppTerraformDirectory = Join-Path $env:TEMP "home-portal-app-$RunId"
$TestArtifactsDirectory = Join-Path $PSScriptRoot "artifacts\$RunId"
$TestBinaryDirectory = Join-Path $PSScriptRoot "bin"
$TestTemporaryDirectory = Join-Path $TestArtifactsDirectory "tmp"
$TestTerraformInitialized = $false
$AppTerraformInitialized = $false

$env:TF_VAR_docker_host = "npipe:////./pipe/docker_engine"
$env:TF_VAR_docker_network = "home-portal-test"
$env:TF_VAR_timezone = "America/Los_Angeles"
$env:TF_VAR_postgres_image = "postgres:17"
$env:TF_VAR_postgres_root_user = "postgres"
$env:TF_VAR_postgres_root_password = "local-test-only"
$env:TF_VAR_postgres_external_port = "55432"
$env:TF_VAR_s3_compatible_image = "localstack/localstack:3.8.1"
$env:TF_VAR_s3_compatible_external_port = "4566"
$env:TF_VAR_aws_cli_image = "amazon/aws-cli:2.18.9"
$env:TF_VAR_backup_s3_bucket = "home-portal-test-backups"
$env:TF_VAR_home_portal_image = "home-portal:local"
$env:TF_VAR_home_portal_container_name = "home-portal-test"
$env:TF_VAR_home_portal_external_port = "18099"
$env:TF_VAR_home_portal_db_host = "postgres"
$env:TF_VAR_home_portal_db_port = "5432"
$env:TF_VAR_home_portal_db_username = "home_portal"
$env:TF_VAR_home_portal_db_password = "local-test-only"
$env:TF_VAR_postgres_host = "localhost"
$env:TF_VAR_postgres_port = "55432"
$env:TF_VAR_oauth2_enabled = "false"
$env:TF_VAR_oauth2_admin = 'email("test@example.com")'
$env:TF_VAR_oauth2_issuer_url = "http://localhost/test-issuer"
$env:TF_VAR_oauth2_auth_url = "http://localhost/test-auth"
$env:TF_VAR_oauth2_token_url = "http://localhost/test-token"
$env:TF_VAR_oauth2_client_id = "home-portal-test"
$env:TF_VAR_oauth2_client_secret = "local-test-only"
$env:TF_VAR_oauth2_client_scope = " "
$env:TF_VAR_backup_aws_image = "amazon/aws-cli:2.18.9"
$env:TF_VAR_backup_archive_name = "home-portal-test-backup.zip"
$env:TF_VAR_backup_install_path = $TestBinaryDirectory
$env:TF_VAR_backup_tmp_dir = $TestTemporaryDirectory
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
$env:AWS_DEFAULT_REGION = "us-east-1"
$env:AWS_S3_ENDPOINT_URL = "http://localstack:4566"

function Invoke-Terraform {
    param(
        [string[]] $Arguments,
        [switch] $AllowFailure
    )

    $PreviousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $TerraformExecutable @Arguments 2>&1
        $TerraformExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $PreviousErrorActionPreference
    }

    if ($TerraformExitCode -ne 0) {
        if ($AllowFailure) {
            Write-Warning "Terraform exited with code $TerraformExitCode"
            return
        }
        throw "Terraform exited with code $TerraformExitCode"
    }
}

function Invoke-Docker {
    param([string[]] $Arguments)

    $PreviousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & docker @Arguments 2>&1
        $DockerExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $PreviousErrorActionPreference
    }

    if ($DockerExitCode -ne 0) {
        throw "Docker exited with code $DockerExitCode"
    }
}

function Invoke-TestAwsCli {
    param([string[]] $Arguments)

    Invoke-Docker (@(
        "run", "--rm", "--network", $env:TF_VAR_docker_network,
        "--env", "AWS_ACCESS_KEY_ID=$env:AWS_ACCESS_KEY_ID",
        "--env", "AWS_SECRET_ACCESS_KEY=$env:AWS_SECRET_ACCESS_KEY",
        "--env", "AWS_DEFAULT_REGION=$env:AWS_DEFAULT_REGION",
        $env:TF_VAR_aws_cli_image
    ) + $Arguments)
}

try {
    if ($Down) {
        $AppTerraformInitialized = Test-Path -LiteralPath (Join-Path $AppTerraformDirectory ".terraform")
        $TestTerraformInitialized = $true
        return
    }

    Invoke-Docker @("info")
    Invoke-Docker @("image", "inspect", $env:TF_VAR_home_portal_image)

    New-Item -ItemType Directory -Force -Path $TestBinaryDirectory, $TestTemporaryDirectory | Out-Null

    Invoke-Terraform @("-chdir=$TestTerraformDirectory", "init")
    $TestTerraformInitialized = $true
    Invoke-Terraform @("-chdir=$TestTerraformDirectory", "apply", "-auto-approve")

    New-Item -ItemType Directory -Force -Path $AppTerraformDirectory | Out-Null
    Copy-Item -Path (Join-Path $RootDirectory "terraform\*.tf") -Destination $AppTerraformDirectory -Force
    Copy-Item -Path (Join-Path $RootDirectory "terraform\backup") -Destination $AppTerraformDirectory -Recurse -Force
    Invoke-Terraform @("-chdir=$AppTerraformDirectory", "init")
    $AppTerraformInitialized = $true
    Invoke-Terraform @("-chdir=$AppTerraformDirectory", "apply", "-auto-approve")

    $AppUrl = "http://localhost:18099"
    $HealthReady = $false
    for ($Attempt = 0; $Attempt -lt 60; $Attempt++) {
        try {
            $Health = Invoke-RestMethod -Uri "$AppUrl/health-check" -TimeoutSec 5
            if ($Health.success) {
                $HealthReady = $true
                break
            }
        }
        catch {
            Start-Sleep -Seconds 2
        }
    }
    if (-not $HealthReady) {
        throw "Home Portal did not become healthy"
    }

    if ($Up) {
        $KeepResources = $true
        Write-Host ""
        Write-Host "Home Portal is running at $AppUrl"
        Write-Host "Backup script:  $(Join-Path $TestBinaryDirectory 'home-portal-backup.ps1')"
        Write-Host "Restore script: $(Join-Path $TestBinaryDirectory 'home-portal-restore.ps1')"
        Write-Host "Set these before running the scripts:"
        Write-Host "  `$env:AWS_ACCESS_KEY_ID='test'; `$env:AWS_SECRET_ACCESS_KEY='test'; `$env:AWS_DEFAULT_REGION='us-east-1'; `$env:AWS_S3_ENDPOINT_URL='http://localstack:4566'"
        Write-Host "Tear down with: .\test\run.ps1 -Down"
        return
    }

    $TestLinkName = "backup-restore-test"
    $TestLinkUrl = "https://example.invalid/backup-restore-test"
    & $CurlExecutable --fail --silent --show-error --form "href=$TestLinkUrl" "$AppUrl/api/links/$TestLinkName"
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create the backup test link"
    }

    if (-not ((Invoke-RestMethod -Uri "$AppUrl/api/links").href -contains $TestLinkUrl)) {
        throw "Could not create the backup test link"
    }

    & (Join-Path $TestBinaryDirectory "home-portal-backup.ps1")
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "Backup script failed with exit code $LASTEXITCODE"
    }
    $HostBackupFile = Join-Path $TestTemporaryDirectory $env:TF_VAR_backup_archive_name
    if (Test-Path -LiteralPath $HostBackupFile) {
        throw "Backup script left a temporary host archive behind"
    }

    Invoke-TestAwsCli @(
        "s3api", "head-object",
        "--endpoint-url", $env:AWS_S3_ENDPOINT_URL,
        "--bucket", $env:TF_VAR_backup_s3_bucket,
        "--key", $env:TF_VAR_backup_archive_name
    )

    Invoke-RestMethod -Method Delete -Uri "$AppUrl/api/links/$TestLinkName" | Out-Null
    if ((Invoke-RestMethod -Uri "$AppUrl/api/links").href -contains $TestLinkUrl) {
        throw "Could not remove the backup test link before restore"
    }

    & (Join-Path $TestBinaryDirectory "home-portal-restore.ps1")
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "Restore script failed with exit code $LASTEXITCODE"
    }
    if (Test-Path -LiteralPath $HostBackupFile) {
        throw "Restore script left a temporary host archive behind"
    }

    $RestoredLinks = Invoke-RestMethod -Uri "$AppUrl/api/links"
    if (-not ($RestoredLinks.href -contains $TestLinkUrl)) {
        throw "Restore did not recover the backed-up test link"
    }

    Write-Host "Local Home Portal backup/restore test passed"
}
catch {
    Write-Host "Integration test failed: $($_.Exception.Message)"
    $ContainerName = Invoke-Docker @(
        "container", "ls",
        "--filter", "name=$env:TF_VAR_home_portal_container_name",
        "--format", "{{.Names}}"
    )
    if ($ContainerName) {
        Invoke-Docker @("logs", $env:TF_VAR_home_portal_container_name)
    }
    throw
}
finally {
    if (-not $KeepResources) {
    if ($AppTerraformInitialized) {
        Invoke-Terraform @("-chdir=$AppTerraformDirectory", "destroy", "-auto-approve") -AllowFailure
    }
    if ($TestTerraformInitialized) {
        Invoke-Terraform @("-chdir=$TestTerraformDirectory", "destroy", "-auto-approve") -AllowFailure
    }
    if (Test-Path -LiteralPath $AppTerraformDirectory) {
        for ($Attempt = 0; $Attempt -lt 5; $Attempt++) {
            try {
                Remove-Item -LiteralPath $AppTerraformDirectory -Recurse -Force -ErrorAction Stop
                break
            }
            catch {
                if ($Attempt -eq 4) {
                    Write-Warning "Could not remove temporary Terraform files at $AppTerraformDirectory"
                }
                else {
                    Start-Sleep -Seconds 2
                }
            }
        }
    }
    if (Test-Path -LiteralPath $TestArtifactsDirectory) {
        Remove-Item -LiteralPath $TestArtifactsDirectory -Recurse -Force
    }
    if (Test-Path -LiteralPath $TestBinaryDirectory) {
        Get-ChildItem -LiteralPath $TestBinaryDirectory -File -Filter "home-portal-*.ps1" |
            Remove-Item -Force
        if (-not (Get-ChildItem -LiteralPath $TestBinaryDirectory -Force)) {
            Remove-Item -LiteralPath $TestBinaryDirectory -Force
        }
    }
    }
}
