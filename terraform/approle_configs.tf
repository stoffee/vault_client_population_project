# AppRole configurations for client script authentication
# Each configuration allows a specific client to authenticate to Vault

# Database credential rotation - thiccboi
resource "vault_approle_auth_backend_role" "db_rotation" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.databases.path}"
  backend             = vault_auth_backend.approle_databases.path
  role_name           = "db-rotation-role"
  token_ttl           = 3600
  token_max_ttl       = 7200
  token_policies      = [vault_policy.db_client_expanded.name]
}

resource "vault_approle_auth_backend_role_id" "db_rotation_role_id" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.databases.path}"
  backend             = vault_auth_backend.approle_databases.path
  role_name           = vault_approle_auth_backend_role.db_rotation.role_name
}

resource "vault_approle_auth_backend_secret_id" "db_rotation_secret_id" {
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

resource "vault_approle_auth_backend_role_id" "cert_renewal_role_id" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
  backend             = vault_auth_backend.approle_pki_internal.path
  role_name           = vault_approle_auth_backend_role.cert_renewal.role_name
}

resource "vault_approle_auth_backend_secret_id" "cert_renewal_secret_id" {
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

resource "vault_approle_auth_backend_role_id" "ssh_rotation_role_id" {
  namespace           = "${vault_namespace.project.path}/${vault_namespace.ssh.path}"
  backend             = vault_auth_backend.approle_ssh.path
  role_name           = vault_approle_auth_backend_role.ssh_rotation.role_name
}

resource "vault_approle_auth_backend_secret_id" "ssh_rotation_secret_id" {
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
resource "vault_cert_auth_backend_role" "web_cert_role" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.pki_web.path}"
  backend   = vault_auth_backend.tls_pki_web.path
  name      = "web-cert-role"
  certificate = file("${path.module}/dummy-client-cert.pem")
  token_policies = [vault_policy.web_cert_expanded.name]
  token_ttl = 3600
  depends_on = [local_file.dummy_client_cert]
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

/*
# Batch processing - Username/Password auth
resource "vault_generic_endpoint" "batch_user" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.batch.path}"
  path      = "auth/userpass/users/batch-processor"
  
  data_json = jsonencode({
    password = "batch-demo-password"
    policies = [vault_policy.batch_job_policy.name]
  })

  depends_on = [vault_auth_backend.userpass_batch]
}

# Security admin - Username/Password auth
resource "vault_generic_endpoint" "security_admin" {
  namespace = "${vault_namespace.project.path}/${vault_namespace.security.path}"
  path      = "auth/userpass/users/security-admin"
  
  data_json = jsonencode({
    password = "security-demo-password"
    policies = [vault_policy.security_admin_policy.name]
  })

  depends_on = [vault_auth_backend.userpass_security]
}
*/

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
      password = "batch-demo-password",
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

# Create dummy cert for TLS auth demo
resource "local_file" "dummy_client_cert" {
  filename = "${path.module}/dummy-client-cert.pem"
  content = <<EOF
-----BEGIN CERTIFICATE-----
MIIDazCCAlOgAwIBAgIUJlq+zz9CO2gJbGOEAgRVN3FNWjEwDQYJKoZIhvcNAQEL
BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
GEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAeFw0yMzA0MjAxNDQzMzZaFw0yMzA1
MjAxNDQzMzZaMEUxCzAJBgNVBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEw
HwYDVQQKDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQDPeRhE2uJqPrUf5jZUEKQw5F/MJjwO8ECNihIKKjH5
LpKnJnJZ6rQNXwvmjGpUYDw7DhHhOhS2JbUQU5MykCr4WwJ4JTFLsA8JQP9fu9h/
7GxZOYCpxZJnXUEgpfGEJQy1JLjzZTNYEIMMXlUgYggOgENET+6xBuYIoKNQULKh
NADjMbzxVLJQkbsWreAXLWgbO/DeAA1SMqwBQHgQzvf0x7BcrmQGzJOvuS8XIn8O
JdU04UmVGGjD/jT4vhZ8i5aGDJFjWEYzJBJ3P7sgMZQQ8qK5MpKPgWGTUjyaM/z6
k658LHiVwlWKEliUcLnXqqJGpNwFQiJMUQXomAk9X7GDAgMBAAGjUzBRMB0GA1Ud
DgQWBBSFC1vGuqIgzgR7BUwl3aaNNLHG0TAfBgNVHSMEGDAWgBSFC1vGuqIgzgR7
BUwl3aaNNLHG0TAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQDK
JTEuRWp3DFfM8BoHtUuQ8YaKFwOx6VAj5g8gBHFhKcEPlfuBaMcgsw5wZL90lZAP
EOF
  file_permission = "0600"
}

# Output credentials for use in client scripts
output "client_credentials_file" {
  value = local_file.client_credentials.filename
  description = "Path to the generated client credentials file"
}

output "db_rotation_credentials" {
  value = {
    role_id = vault_approle_auth_backend_role_id.db_rotation_role_id.role_id
    secret_id = nonsensitive(vault_approle_auth_backend_secret_id.db_rotation_secret_id.secret_id)
    namespace = "${vault_namespace.project.path}/${vault_namespace.databases.path}"
  }
  sensitive = true
  description = "Database rotation AppRole credentials"
}

output "cert_renewal_credentials" {
  value = {
    role_id = vault_approle_auth_backend_role_id.cert_renewal_role_id.role_id
    secret_id = nonsensitive(vault_approle_auth_backend_secret_id.cert_renewal_secret_id.secret_id)
    namespace = "${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
  }
  sensitive = true
  description = "Certificate renewal AppRole credentials"
}

output "ssh_rotation_credentials" {
  value = {
    role_id = vault_approle_auth_backend_role_id.ssh_rotation_role_id.role_id
    secret_id = nonsensitive(vault_approle_auth_backend_secret_id.ssh_rotation_secret_id.secret_id)
    namespace = "${vault_namespace.project.path}/${vault_namespace.ssh.path}"
  }
  sensitive = true
  description = "SSH rotation AppRole credentials"
}