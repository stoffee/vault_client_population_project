data "vault_namespace" "admin" {
  path = "admin"
}

resource "vault_namespace" "databases" {
  path      = "databases"
  namespace = vault_namespace.admin.path
}

resource "vault_namespace" "project" {
  path      = var.project_namespace
  namespace = data.vault_namespace.admin.path
}

resource "vault_namespace" "kubernetes" {
  path      = "kubernetes"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}"
}

resource "vault_namespace" "cicd" {
  path      = "cicd"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}"
}

resource "vault_namespace" "pki_web" {
  path      = "pki-web"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}"
}

resource "vault_namespace" "pki_internal" {
  path      = "pki-internal"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}"
}

resource "vault_namespace" "cloud" {
  path      = "cloud"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}"
}

resource "vault_namespace" "applications" {
  path      = "applications"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}"
}

resource "vault_namespace" "ssh" {
  path      = "ssh"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}"
}

resource "vault_namespace" "batch" {
  path      = "batch"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}"
}

resource "vault_namespace" "encryption" {
  path      = "encryption"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}"
}

resource "vault_namespace" "security" {
  path      = "security"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}"
}

resource "vault_namespace" "shared" {
  path      = "shared"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}"
}

resource "vault_namespace" "x509" {
  path      = "x509"
  namespace = "${data.vault_namespace.admin.path}/${vault_namespace.project.path}"
}