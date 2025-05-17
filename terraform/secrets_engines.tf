# KV Secrets Engines
resource "vault_mount" "kv_applications" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.applications.path}"
  path      = "kv"
  type      = "kv"
  options = {
    version = "2"
  }
}

resource "vault_mount" "kv_shared" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.shared.path}"
  path      = "kv"
  type      = "kv"
  options = {
    version = "2"
  }
}

resource "vault_mount" "kv_cicd" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.cicd.path}"
  path      = "kv"
  type      = "kv"
  options = {
    version = "2"
  }
}

resource "vault_mount" "kv_batch" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.batch.path}"
  path      = "kv"
  type      = "kv"
  options = {
    version = "2"
  }
}

resource "vault_mount" "kv_kubernetes" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.kubernetes.path}"
  path      = "kv"
  type      = "kv"
  options = {
    version = "2"
  }
}

resource "vault_mount" "kv_security" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.security.path}"
  path      = "kv"
  type      = "kv"
  options = {
    version = "2"
  }
}

# Database Secrets Engine
resource "vault_mount" "db_databases" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.databases.path}"
  path      = "database"
  type      = "database"
}

# PKI Secrets Engines
resource "vault_mount" "pki_web" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.pki_web.path}"
  path      = "pki"
  type      = "pki"
  max_lease_ttl_seconds = 31536000 # 1 year
}

resource "vault_mount" "pki_internal" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
  path      = "pki"
  type      = "pki"
  max_lease_ttl_seconds = 31536000 # 1 year
}

resource "vault_mount" "pki_x509" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.x509.path}"
  path      = "pki"
  type      = "pki"
  max_lease_ttl_seconds = 31536000 # 1 year
}

# Transit Secrets Engine
resource "vault_mount" "transit_encryption" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.encryption.path}"
  path      = "transit"
  type      = "transit"
}

# AWS Secrets Engine
resource "vault_mount" "aws_cloud" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.cloud.path}"
  path      = "aws"
  type      = "aws"
}

# SSH Secrets Engine
resource "vault_mount" "ssh" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.ssh.path}"
  path      = "ssh"
  type      = "ssh"
}