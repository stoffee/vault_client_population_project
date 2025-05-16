# KV Secrets Engines
resource "vault_mount" "kv_applications" {
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.applications.path}"
  path      = "kv"
  type      = "kv"
  options = {
    version = "2"
  }
}

resource "vault_mount" "kv_shared" {
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.shared.path}"
  path      = "kv"
  type      = "kv"
  options = {
    version = "2"
  }
}

# Database Secrets Engine
resource "vault_mount" "db_databases" {
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.databases.path}"
  path      = "database"
  type      = "database"
}

# PKI Secrets Engines
resource "vault_mount" "pki_web" {
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.pki_web.path}"
  path      = "pki"
  type      = "pki"
  max_lease_ttl_seconds = 31536000 # 1 year
}

resource "vault_mount" "pki_internal" {
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
  path      = "pki"
  type      = "pki"
  max_lease_ttl_seconds = 31536000 # 1 year
}

resource "vault_mount" "pki_x509" {
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.x509.path}"
  path      = "pki"
  type      = "pki"
  max_lease_ttl_seconds = 31536000 # 1 year
}

# Transit Secrets Engine
resource "vault_mount" "transit_encryption" {
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.encryption.path}"
  path      = "transit"
  type      = "transit"
}

# AWS Secrets Engine
resource "vault_mount" "aws_cloud" {
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.cloud.path}"
  path      = "aws"
  type      = "aws"
}

# SSH Secrets Engine
resource "vault_mount" "ssh" {
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.ssh.path}"
  path      = "ssh"
  type      = "ssh"
}