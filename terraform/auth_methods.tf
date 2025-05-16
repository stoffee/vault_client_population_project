resource "vault_auth_backend" "approle_databases" {
  type      = "approle"
  path      = "approle"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.databases.path}"
}

resource "vault_auth_backend" "approle_pki_internal" {
  type      = "approle"
  path      = "approle"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
}

resource "vault_auth_backend" "approle_ssh" {
  type      = "approle"
  path      = "approle"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.ssh.path}"
}

# JWT Auth Methods
resource "vault_jwt_auth_backend" "jwt_cicd" {
  namespace           = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.cicd.path}"
  path                = "jwt"
  jwks_url            = "https://example.com/.well-known/jwks.json"
  bound_issuer        = "https://example.com/"
}

resource "vault_jwt_auth_backend" "jwt_encryption" {
  namespace           = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.encryption.path}"
  path                = "jwt"
  jwks_url            = "https://example.com/.well-known/jwks.json"
  bound_issuer        = "https://example.com/"
}

# Kubernetes Auth
resource "vault_auth_backend" "kubernetes" {
  type      = "kubernetes"
  path      = "kubernetes"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.kubernetes.path}"
}

# TLS Certificate Auth
resource "vault_auth_backend" "tls_pki_web" {
  type      = "cert"
  path      = "cert"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.pki_web.path}"
}

resource "vault_auth_backend" "tls_encryption" {
  type      = "cert"
  path      = "cert"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.encryption.path}"
}

resource "vault_auth_backend" "tls_x509" {
  type      = "cert"
  path      = "cert"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.x509.path}"
}

# OIDC Auth
resource "vault_jwt_auth_backend" "oidc_cloud" {
  namespace           = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.cloud.path}"
  path                = "oidc"
  type                = "oidc"
  oidc_discovery_url  = "https://example.com/"
  oidc_client_id      = "example-client-id"
  oidc_client_secret  = "example-client-secret"
  default_role        = "cloud_role"
}

# Username/Password Auth
resource "vault_auth_backend" "userpass_batch" {
  type      = "userpass"
  path      = "userpass"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.batch.path}"
}

resource "vault_auth_backend" "userpass_security" {
  type      = "userpass"
  path      = "userpass"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}/${vault_namespace.security.path}"
}
