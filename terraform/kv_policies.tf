# KV data access policies
# These policies grant specific access patterns for our client scripts

# Application secrets versioning policy
resource "vault_policy" "app_versioning" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.applications.path}"
  name      = "app-version-checker"
  policy    = <<EOF
# Allow reading application secrets
path "kv/data/app/*" {
  capabilities = ["read"]
}

# Allow checking metadata (versions)
path "kv/metadata/app/*" {
  capabilities = ["read", "list"]
}

# Allow reading specific versions
path "kv/data/config/database" {
  capabilities = ["read"]
}

path "kv/metadata/config/database" {
  capabilities = ["read"]
}
EOF
}

# CI/CD environment secrets policy - expanded
resource "vault_policy" "cicd_environments" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.cicd.path}"
  name      = "cicd-environments"
  policy    = <<EOF
# Allow reading all environment secrets
path "kv/data/environments/*" {
  capabilities = ["read"]
}

# Allow listing environments
path "kv/metadata/environments" {
  capabilities = ["list"]
}

# Allow checking versions
path "kv/metadata/environments/*" {
  capabilities = ["read"]
}
EOF
}

# Batch job policy
resource "vault_policy" "batch_job_policy" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.batch.path}"
  name      = "batch-job-policy"
  policy    = <<EOF
# Allow batch jobs to read their configuration
path "kv/data/jobs/batch-*" {
  capabilities = ["read"]
}

# Allow listing available jobs
path "kv/metadata/jobs" {
  capabilities = ["list"]
}

# Allow checking job metadata
path "kv/metadata/jobs/batch-*" {
  capabilities = ["read"]
}
EOF
}

# Security admin policy
resource "vault_policy" "security_admin_policy" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.security.path}"
  name      = "security-admin-policy"
  policy    = <<EOF
# Allow management of security-related secrets
path "kv/data/*" {
  capabilities = ["create", "read", "update", "delete"]
}

path "kv/metadata/*" {
  capabilities = ["list", "read", "delete"]
}

# Allow generation of TOTP secrets
path "totp/*" {
  capabilities = ["create", "read", "update", "delete"]
}
EOF
}

# Shared access policy for cross-namespace access
resource "vault_policy" "shared_access" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.shared.path}"
  name      = "shared-access"
  policy    = <<EOF
# Allow read-only access to shared secrets
path "kv/data/access/*" {
  capabilities = ["read"]
}

# Allow listing shared secrets
path "kv/metadata/access" {
  capabilities = ["list"]
}

# Allow read-only access to global config
path "kv/data/global/config" {
  capabilities = ["read"]
}
EOF
}

# Database client policy - expanded with more permissions
resource "vault_policy" "db_client_expanded" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.databases.path}"
  name      = "db-client-expanded"
  policy    = <<EOF
# Allow generating database credentials
path "database/creds/readonly" {
  capabilities = ["read"]
}

# Allow listing roles
path "database/roles" {
  capabilities = ["list"]
}

# Allow reading role information
path "database/roles/readonly" {
  capabilities = ["read"]
}

# Allow revoking leases (for rotation)
path "sys/leases/revoke/database/creds/readonly/*" {
  capabilities = ["update"]
}
EOF
}

# Transit encryption policy
resource "vault_policy" "encryption_service" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.encryption.path}"
  name      = "encryption-service"
  policy    = <<EOF
# Allow encryption operations
path "transit/encrypt/app-encryption-key" {
  capabilities = ["update"]
}

# Allow decryption operations
path "transit/decrypt/app-encryption-key" {
  capabilities = ["update"]
}

# Allow signing operations
path "transit/sign/document-signing-key" {
  capabilities = ["update"]
}

# Allow signature verification
path "transit/verify/document-signing-key" {
  capabilities = ["update"]
}
EOF
}

# AWS credential access policy
resource "vault_policy" "aws_credential_access" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.cloud.path}"
  name      = "aws-credential-access"
  policy    = <<EOF
# Allow generating AWS credentials
path "aws/creds/dynamic-role" {
  capabilities = ["read"]
}

# Allow listing available roles
path "aws/roles" {
  capabilities = ["list"]
}

# Allow reading role information
path "aws/roles/dynamic-role" {
  capabilities = ["read"]
}
EOF
}

# SSH key signing policy
resource "vault_policy" "ssh_signing" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.ssh.path}"
  name      = "ssh-signing-policy"
  policy    = <<EOF
# Allow signing SSH keys
path "ssh/sign/server-role" {
  capabilities = ["update"]
}

# Allow listing roles
path "ssh/roles" {
  capabilities = ["list"]
}

# Allow reading public key
path "ssh/public_key" {
  capabilities = ["read"]
}
EOF
}

# Kubernetes secret access policy - expanded
resource "vault_policy" "k8s_service_policy" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.kubernetes.path}"
  name      = "k8s-service-policy"
  policy    = <<EOF
# Allow reading secrets
path "kv/data/*" {
  capabilities = ["read"]
}

# Allow listing secret paths
path "kv/metadata/*" {
  capabilities = ["list"]
}

# Allow reading specific environments
path "kv/data/environments/*" {
  capabilities = ["read"]
}
EOF
}

# Cross-namespace policy template for each node
# This policy allows access to shared secrets from any namespace
resource "vault_policy" "cross_namespace_access" {
  for_each = {
    thiccboi = vault_namespace.applications.path,
    lincoln  = vault_namespace.kubernetes.path,
    nugget   = vault_namespace.cicd.path,
    beebutt  = vault_namespace.pki_web.path,
    lilikoi  = vault_namespace.encryption.path
  }

  namespace = "${vault_namespace.project.path}/${each.value}"
  name      = "cross-namespace-access"
  policy    = <<EOF
# Allow reading from shared namespace
path "${vault_namespace.project.path}/${vault_namespace.shared.path}/kv/data/access/*" {
  capabilities = ["read"]
}

# Allow reading global config from shared namespace
path "${vault_namespace.project.path}/${vault_namespace.shared.path}/kv/data/global/config" {
  capabilities = ["read"]
}
EOF
}

# Web certificate client policy - expanded
resource "vault_policy" "web_cert_expanded" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.pki_web.path}"
  name      = "web-cert-expanded"
  policy    = <<EOF
# Allow issuing certificates
path "pki/issue/web-server" {
  capabilities = ["create", "update"]
}

# Allow listing certificate roles
path "pki/roles" {
  capabilities = ["list"]
}

# Allow reading role information
path "pki/roles/web-server" {
  capabilities = ["read"]
}

# Allow reading the CA cert
path "pki/cert/ca" {
  capabilities = ["read"]
}
EOF
}

# Internal certificate client policy - expanded
resource "vault_policy" "internal_cert_expanded" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
  name      = "internal-cert-expanded"
  policy    = <<EOF
# Allow issuing certificates
path "pki/issue/internal" {
  capabilities = ["create", "update"]
}

# Allow listing certificate roles
path "pki/roles" {
  capabilities = ["list"]
}

# Allow reading role information
path "pki/roles/internal" {
  capabilities = ["read"]
}

# Allow reading the CA cert
path "pki/cert/ca" {
  capabilities = ["read"]
}
EOF
}