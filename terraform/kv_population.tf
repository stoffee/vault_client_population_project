# Random generation of KV data for each namespace
# Using fun random providers to create variety

# Random Pet provider for friendly names
resource "random_pet" "application_names" {
  count     = 8
  length    = 2
  separator = "-"
}

resource "random_pet" "environment_names" {
  count     = 4
  length    = 1
}

resource "random_pet" "database_names" {
  count     = 5
  length    = 1
  separator = "_"
}

# Random passwords and UUIDs
resource "random_password" "app_secrets" {
  count   = 8
  length  = 16
  special = true
}

resource "random_password" "db_passwords" {
  count   = 5
  length  = 20
  special = true
}

resource "random_uuid" "api_keys" {
  count = 6
}

# Random text for fun descriptions
resource "random_shuffle" "adjectives" {
  input        = ["magical", "mysterious", "powerful", "elegant", "robust", "secure", "efficient", "vibrant", "dynamic", "innovative"]
  result_count = 10
}

# Random integers for various config values
resource "random_integer" "port_numbers" {
  count = 8
  min   = 3000
  max   = 9000
}

resource "random_integer" "timeout_values" {
  count = 5
  min   = 30
  max   = 300
}

# Random IP address generation for mock endpoints
resource "random_integer" "ip_segments" {
  count = 12
  min   = 1
  max   = 254
}

# Applications namespace KV data
resource "vault_kv_secret_v2" "applications_secrets" {
  count     = 5
  namespace = "${vault_namespace.project.path}/${vault_namespace.applications.path}"
  mount     = vault_mount.kv_applications.path
  name      = "app/${random_pet.application_names[count.index].id}"
  data_json = jsonencode({
    api_key       = random_uuid.api_keys[count.index].result
    secret_key    = random_password.app_secrets[count.index].result
    environment   = random_pet.environment_names[count.index % 4].id
    port          = random_integer.port_numbers[count.index].result
    description   = "A ${random_shuffle.adjectives.result[count.index]} application for ${random_pet.environment_names[count.index % 4].id} environment"
    last_rotation = "2023-${(count.index % 12) + 1}-${(count.index % 28) + 1}"
    version       = "v${count.index + 1}.${(count.index * 2) % 10}.${count.index % 5}"
  })
}

# Versioned secrets for application config
resource "vault_kv_secret_v2" "application_configs" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.applications.path}"
  mount     = vault_mount.kv_applications.path
  name      = "config/database"
  data_json = jsonencode({
    host        = "db-${random_pet.database_names[0].id}.example.com"
    username    = "app_user"
    password    = random_password.db_passwords[0].result
    database    = random_pet.database_names[0].id
    max_connections = random_integer.timeout_values[0].result
    timeout     = random_integer.timeout_values[1].result
  })
}

# CICD namespace KV data for different environments
resource "vault_kv_secret_v2" "cicd_environments" {
  for_each  = {
    dev  = 0
    test = 1
    stage = 2
    prod = 3
  }
  
  namespace = "${vault_namespace.project.path}/${vault_namespace.cicd.path}"
  mount     = "kv"  # We'll create this mount in secrets_engines.tf
  name      = "environments/${each.key}"
  data_json = jsonencode({
    api_key       = random_uuid.api_keys[each.value].result
    deploy_token  = random_password.app_secrets[each.value + 4].result
    env_name      = random_pet.environment_names[each.value].id
    region        = each.value == 3 ? "us-west-2" : "us-east-1"
    log_level     = each.key == "prod" ? "info" : "debug"
    notify_on_deploy = each.key == "prod" ? true : false
    timeout       = random_integer.timeout_values[each.value].result
    max_instances = each.value * 2 + 2
  })
}

# Shared namespace KV data
resource "vault_kv_secret_v2" "shared_configs" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.shared.path}"
  mount     = vault_mount.kv_shared.path
  name      = "global/config"
  data_json = jsonencode({
    company_name = "Hashistack Adventures Inc."
    support_email = "support@example.com"
    api_endpoint = "https://${random_integer.ip_segments[0].result}.${random_integer.ip_segments[1].result}.${random_integer.ip_segments[2].result}.${random_integer.ip_segments[3].result}/api"
    max_retries = random_integer.timeout_values[4].result
    default_timeout = random_integer.timeout_values[3].result
    feature_flags = {
      enable_new_ui = true
      use_cache = true
      experimental = false
    }
  })
}

# Create shared secrets for cross-namespace access testing
resource "vault_kv_secret_v2" "shared_secrets" {
  count     = 3
  namespace = "${vault_namespace.project.path}/${vault_namespace.shared.path}"
  mount     = vault_mount.kv_shared.path
  name      = "access/secret-${count.index + 1}"
  data_json = jsonencode({
    name         = random_pet.application_names[count.index + 5].id
    description  = "A ${random_shuffle.adjectives.result[count.index + 5]} shared secret"
    access_key   = random_uuid.api_keys[count.index + 3].result
    secret_value = random_password.app_secrets[count.index + 2].result
    created_at   = "2023-${(count.index % 12) + 1}-${(count.index % 28) + 1}"
  })
}

# Create KV mount for CICD namespace
resource "vault_mount" "kv_cicd" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.cicd.path}"
  path      = "kv"
  type      = "kv"
  options = {
    version = "2"
  }
}

# Create KV mount for batch namespace
resource "vault_mount" "kv_batch" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.batch.path}"
  path      = "kv"
  type      = "kv"
  options = {
    version = "2"
  }
}

# Add batch job configuration
resource "vault_kv_secret_v2" "batch_configs" {
  count     = 4
  namespace = "${vault_namespace.project.path}/${vault_namespace.batch.path}"
  mount     = vault_mount.kv_batch.path
  name      = "jobs/batch-${count.index + 1}"
  data_json = jsonencode({
    job_name     = "batch-${random_pet.application_names[count.index].id}"
    description  = "A ${random_shuffle.adjectives.result[count.index]} batch job"
    schedule     = count.index == 0 ? "0 * * * *" : (count.index == 1 ? "0 0 * * *" : (count.index == 2 ? "0 0 * * 0" : "0 0 1 * *"))
    timeout      = random_integer.timeout_values[count.index % 5].result
    max_retries  = count.index + 1
    priority     = count.index == 3 ? "high" : (count.index == 0 ? "low" : "medium")
    notify_email = count.index == 3 ? "alerts@example.com" : "batch@example.com"
  })
}

# Add dummy credentials for the AWS secret engine
resource "vault_aws_secret_backend_role" "cloud_role" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.cloud.path}"
  backend   = vault_mount.aws_cloud.path
  name      = "dynamic-role"
  credential_type = "iam_user"
  
  policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOF
}

# Create sample PostgreSQL role (note: this just creates the role definition, not the actual connection)
resource "vault_database_secret_backend_role" "postgres_role" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.databases.path}"
  backend   = vault_mount.db_databases.path
  name      = "readonly"
  db_name   = "postgres"
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT;",
    "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
  ]
  default_ttl = 3600
  max_ttl     = 86400
}

# Set up the encryption keys in the transit engine
resource "vault_transit_secret_backend_key" "encryption_key" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.encryption.path}"
  backend   = vault_mount.transit_encryption.path
  name      = "app-encryption-key"
  derived   = true
  type      = "aes256-gcm96"
}

resource "vault_transit_secret_backend_key" "signing_key" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.encryption.path}"
  backend   = vault_mount.transit_encryption.path
  name      = "document-signing-key"
  type      = "ed25519"
}

# Set up dummy users for password auth
resource "vault_generic_endpoint" "batch_user" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.batch.path}"
  path      = "auth/userpass/users/batch-processor"
  
  data_json = jsonencode({
    password = "dummy-password-for-testing"
    policies = ["batch-job-policy"]
  })
  depends_on = [vault_auth_backend.userpass_batch]
}

resource "vault_generic_endpoint" "security_user" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.security.path}"
  path      = "auth/userpass/users/security-admin"
  
  data_json = jsonencode({
    password = "security-password-for-testing"
    policies = ["security-admin-policy"]
  })

  depends_on = [vault_auth_backend.userpass_security]
}

# PKI configuration for web certificates
resource "vault_pki_secret_backend_root_cert" "pki_web_root" {
  namespace    = "${vault_namespace.project.path}/${vault_namespace.pki_web.path}"
  backend      = vault_mount.pki_web.path
  type         = "internal"
  common_name  = "Web PKI Root CA"
  ttl          = "87600h" # 10 years
}

resource "vault_pki_secret_backend_role" "web_server" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.pki_web.path}"
  backend             = vault_mount.pki_web.path
  name                = "web-server"
  allowed_domains     = ["example.com", "app.example.com", "internal.example.com"]
  allow_subdomains    = true
  max_ttl             = "72h"
  key_type            = "rsa"
  key_bits            = 2048
  allowed_uri_sans    = ["uri:app:example"]
  require_cn          = false
}

# PKI configuration for internal certificates
resource "vault_pki_secret_backend_root_cert" "pki_internal_root" {
  namespace    = "${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
  backend      = vault_mount.pki_internal.path
  type         = "internal"
  common_name  = "Internal PKI Root CA"
  ttl          = "87600h" # 10 years
}

resource "vault_pki_secret_backend_role" "internal" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
  backend             = vault_mount.pki_internal.path
  name                = "internal"
  allowed_domains     = ["service.internal", "app.internal"]
  allow_subdomains    = true
  max_ttl             = "72h"
  key_type            = "rsa"
  key_bits            = 2048
  allow_ip_sans       = true
  allowed_uri_sans    = ["uri:service:*"]
  require_cn          = false
}

# Dummy SSH signing role
resource "vault_ssh_secret_backend_role" "ssh_role" {
  namespace      = "${vault_namespace.project.path}/${vault_namespace.ssh.path}"
  backend        = vault_mount.ssh.path
  name           = "server-role"
  key_type       = "ca"
  allow_user_certificates = true
  allowed_users  = "*"
  default_user   = "ubuntu"
  ttl            = "24h"
}

# Generate an SSH key pair
resource "tls_private_key" "ssh_ca_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Configure SSH CA with the generated key
resource "vault_ssh_secret_backend_ca" "ssh_ca" {
  namespace   = "${vault_namespace.project.path}/${vault_namespace.ssh.path}"
  backend     = vault_mount.ssh.path
  private_key = tls_private_key.ssh_ca_key.private_key_pem
  public_key  = tls_private_key.ssh_ca_key.public_key_openssh
}