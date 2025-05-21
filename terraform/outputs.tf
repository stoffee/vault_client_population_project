# Output credentials for use in client scripts
# Replace the existing client_credentials_file output with:
output "encryption_service_credentials" {
  value = {
    token     = nonsensitive(vault_token.encryption_token.client_token)
    namespace = "${vault_namespace.project.path}/${vault_namespace.encryption.path}"
  }
  description = "Encryption service credentials for lilikoi"
}

output "db_rotation_credentials" {
  value = {
    role_id = data.vault_approle_auth_backend_role_id.db_rotation_role_id.role_id
    secret_id = nonsensitive(vault_approle_auth_backend_role_secret_id.db_rotation_secret_id.secret_id)
    namespace = "${vault_namespace.project.path}/${vault_namespace.databases.path}"
  }
  description = "Database rotation AppRole Creds"
}

output "cert_renewal_credentials" {
  value = {
    role_id = data.vault_approle_auth_backend_role_id.cert_renewal_role_id.role_id
    secret_id = nonsensitive(vault_approle_auth_backend_role_secret_id.cert_renewal_secret_id.secret_id)
    namespace = "${vault_namespace.project.path}/${vault_namespace.pki_internal.path}"
  }
  description = "Certificate renewal AppRole credentials"
}

output "ssh_rotation_credentials" {
  value = {
    role_id = data.vault_approle_auth_backend_role_id.ssh_rotation_role_id.role_id
    secret_id = nonsensitive(vault_approle_auth_backend_role_secret_id.ssh_rotation_secret_id.secret_id)
    namespace = "${vault_namespace.project.path}/${vault_namespace.ssh.path}"
  }
  description = "SSH rotation AppRole credentials"
}