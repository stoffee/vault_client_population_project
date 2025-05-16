# Database client policy
resource "vault_policy" "db_client" {
  namespace = "admin/${vault_namespace.project.path}/${vault_namespace.databases.path}"
  name      = "db-client"
  policy    = <<EOF
path "database/creds/readonly" {
  capabilities = ["read"]
}
EOF
}

# Kubernetes client policy
resource "vault_policy" "k8s_client" {
  namespace = "admin/${vault_namespace.project.path}/${vault_namespace.kubernetes.path}"
  name      = "k8s-client"
  policy    = <<EOF
path "kv/*" {
  capabilities = ["read"]
}
EOF
}

# CI/CD pipeline policy
resource "vault_policy" "cicd_client" {
  namespace = "admin/${vault_namespace.project.path}/${vault_namespace.cicd.path}"
  name      = "cicd-client"
  policy    = <<EOF
path "kv/data/environments/*" {
  capabilities = ["read"]
}
EOF
}

# Web certificates policy
resource "vault_policy" "web_cert_client" {
  namespace = "admin/${vault_namespace.project.path}/${vault_namespace.pki_web.path}"
  name      = "web-cert-client"
  policy    = <<EOF
path "pki/issue/web-server" {
  capabilities = ["create", "update"]
}
EOF
}

# Internal certificates policy
resource "vault_policy" "internal_cert_client" {
  namespace = "admin/${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
  name      = "internal-cert-client"
  policy    = <<EOF
path "pki/issue/internal" {
  capabilities = ["create", "update"]
}
EOF
}