# Output credentials for use in client scripts
output "client_credentials_file" {
  value = local_file.client_credentials.filename
  description = "Path to the generated client credentials file"
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