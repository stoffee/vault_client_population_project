# Database credential rotation - thiccboi
resource "vault_approle_auth_backend_role" "db_rotation" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.databases.path}"
  backend             = vault_auth_backend.approle_databases.path
  role_name           = "db-rotation-approle-role"
  token_ttl           = 3600
  token_max_ttl       = 7200
  token_policies      = [vault_policy.db_client_expanded.name]
}

data "vault_approle_auth_backend_role_id" "db_rotation_role_id" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.databases.path}"
  backend             = vault_auth_backend.approle_databases.path
  role_name           = vault_approle_auth_backend_role.db_rotation.role_name
}

resource "vault_approle_auth_backend_role_secret_id" "db_rotation_secret_id" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.databases.path}"
  backend             = vault_auth_backend.approle_databases.path
  role_name           = vault_approle_auth_backend_role.db_rotation.role_name
}

# Internal certificate renewal - lilikoi
resource "vault_approle_auth_backend_role" "cert_renewal" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
  backend             = vault_auth_backend.approle_pki_internal.path
  role_name           = "cert-renewal-role"
  token_ttl           = 3600
  token_max_ttl       = 7200
  token_policies      = [vault_policy.internal_cert_expanded.name]
}

data "vault_approle_auth_backend_role_id" "cert_renewal_role_id" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
  backend             = vault_auth_backend.approle_pki_internal.path
  role_name           = vault_approle_auth_backend_role.cert_renewal.role_name
}

resource "vault_approle_auth_backend_role_secret_id" "cert_renewal_secret_id" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
  backend             = vault_auth_backend.approle_pki_internal.path
  role_name           = vault_approle_auth_backend_role.cert_renewal.role_name
}

# SSH key rotation - nugget
resource "vault_approle_auth_backend_role" "ssh_rotation" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.ssh.path}"
  backend             = vault_auth_backend.approle_ssh.path
  role_name           = "ssh-rotation-role"
  token_ttl           = 3600
  token_max_ttl       = 7200
  token_policies      = [vault_policy.ssh_signing.name]
}

data "vault_approle_auth_backend_role_id" "ssh_rotation_role_id" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.ssh.path}"
  backend             = vault_auth_backend.approle_ssh.path
  role_name           = vault_approle_auth_backend_role.ssh_rotation.role_name
}

resource "vault_approle_auth_backend_role_secret_id" "ssh_rotation_secret_id" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.ssh.path}"
  backend             = vault_auth_backend.approle_ssh.path
  role_name           = vault_approle_auth_backend_role.ssh_rotation.role_name
}

# Secret versioning client - thiccboi - Token auth
resource "vault_token" "app_version_token" {
  namespace       = "${vault_namespace.project.path}/${vault_namespace.applications.path}"
  policies        = [vault_policy.app_versioning.name]
  renewable       = true
  ttl             = "24h"
  display_name    = "app-version-checker"
}

# AWS credentials - lincoln - Token auth
resource "vault_token" "aws_cred_token" {
  namespace       = "${vault_namespace.project.path}/${vault_namespace.cloud.path}"
  policies        = [vault_policy.aws_credential_access.name]
  renewable       = true
  ttl             = "24h"
  display_name    = "aws-cred-client"
}

# Transit encryption - lilikoi - Token auth
resource "vault_token" "encryption_token" {
  namespace       = "${vault_namespace.project.path}/${vault_namespace.encryption.path}"
  policies        = [vault_policy.encryption_service.name]
  renewable       = true
  ttl             = "24h"
  display_name    = "encryption-service-client"
}


# Web certificate role - TLS auth
# Generate a proper certificate for TLS auth
resource "tls_private_key" "cert_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.cert_key.private_key_pem
  
  subject {
    common_name  = "client.blahblah.com"
    organization = "blahblah corp"
  }

  validity_period_hours = 24
  
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

# Use the valid certificate
resource "vault_cert_auth_backend_role" "web_cert_role" {
  namespace      = "${vault_namespace.project.path}/${vault_namespace.pki_web.path}"
  backend        = vault_auth_backend.tls_pki_web.path
  name           = "web-cert-role"
  certificate    = tls_self_signed_cert.cert.cert_pem
  token_policies = [vault_policy.web_cert_expanded.name]
  token_ttl      = 3600
}

# CI/CD pipeline - JWT auth
resource "vault_jwt_auth_backend_role" "cicd_role" {
  namespace      = "${vault_namespace.project.path}/${vault_namespace.cicd.path}"
  backend        = "jwt" # Should match your auth backend path
  role_name      = "cicd-role"
  token_policies = [vault_policy.cicd_environments.name]
  
  bound_audiences = ["vault-cicd"]
  user_claim      = "sub"
  role_type       = "jwt"
  bound_claims_type = "glob"
  bound_claims = {
    pipeline = "*"
  }
  depends_on = [vault_auth_backend.jwt_cicd]
}

# Kubernetes auth
resource "vault_kubernetes_auth_backend_role" "k8s_role" {
  namespace       = "${vault_namespace.project.path}/${vault_namespace.kubernetes.path}"
  backend         = vault_auth_backend.kubernetes.path
  role_name       = "k8s-app-role"
  bound_service_account_names = ["app-service-account"]
  bound_service_account_namespaces = ["default", "app"]
  token_ttl       = 3600
  token_policies  = [vault_policy.k8s_service_policy.name]
}

# Cross-namespace tokens
resource "vault_token" "cross_namespace_tokens" {
  for_each = {
    thiccboi = vault_namespace.applications.path,
    lincoln  = vault_namespace.kubernetes.path,
    nugget   = vault_namespace.cicd.path,
    beebutt  = vault_namespace.pki_web.path,
    lilikoi  = vault_namespace.encryption.path
  }

  namespace       = "${vault_namespace.project.path}/${each.value}"
  policies        = ["cross-namespace-access"]
  renewable       = true
  ttl             = "24h"
  display_name    = "${each.key}-cross-namespace-client"

  depends_on = [vault_policy.cross_namespace_access]
}

# Create credential lookup file for client scripts
resource "local_file" "client_credentials" {
  filename = "${path.module}/client_credentials.json"
  content = jsonencode({
    database_rotation = {
      role_id = data.vault_approle_auth_backend_role_id.db_rotation_role_id.role_id,
      secret_id = vault_approle_auth_backend_role_secret_id.db_rotation_secret_id.secret_id,
      namespace = "${vault_namespace.project.path}/${vault_namespace.databases.path}"
    },
    certificate_renewal = {
      role_id = data.vault_approle_auth_backend_role_id.cert_renewal_role_id.role_id,
      secret_id = vault_approle_auth_backend_role_secret_id.cert_renewal_secret_id.secret_id,
      namespace = "${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
    },
    ssh_rotation = {
      role_id = data.vault_approle_auth_backend_role_id.ssh_rotation_role_id.role_id,
      secret_id = vault_approle_auth_backend_role_secret_id.ssh_rotation_secret_id.secret_id,
      namespace = "${vault_namespace.project.path}/${vault_namespace.ssh.path}"
    },
    app_version = {
      token = vault_token.app_version_token.client_token,
      namespace = "${vault_namespace.project.path}/${vault_namespace.applications.path}"
    },
    aws_credentials = {
      token = vault_token.aws_cred_token.client_token,
      namespace = "${vault_namespace.project.path}/${vault_namespace.cloud.path}"
    },
    encryption_service = {
      token = vault_token.encryption_token.client_token,
      namespace = "${vault_namespace.project.path}/${vault_namespace.encryption.path}"
    },
    batch_user = {
      username = "batch-processor",
      password = "dummy-password-for-testing",
      namespace = "${vault_namespace.project.path}/${vault_namespace.batch.path}"
    },
    security_admin = {
      username = "security-admin",
      password = "security-demo-password",
      namespace = "${vault_namespace.project.path}/${vault_namespace.security.path}"
    },
    cross_namespace = {
      thiccboi = vault_token.cross_namespace_tokens["thiccboi"].client_token,
      lincoln = vault_token.cross_namespace_tokens["lincoln"].client_token,
      nugget = vault_token.cross_namespace_tokens["nugget"].client_token,
      beebutt = vault_token.cross_namespace_tokens["beebutt"].client_token,
      lilikoi = vault_token.cross_namespace_tokens["lilikoi"].client_token
    }
  })

  # Only for demo purposes
  file_permission = "0600"
}

