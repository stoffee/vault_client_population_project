resource "vault_namespace" "databases" {
  path      = "databases"
  namespace = "${vault_namespace.project.path}"
}

resource "vault_namespace" "project" {
  path      = var.project_namespace
  namespace = "admin"
}

resource "vault_namespace" "kubernetes" {
  path      = "kubernetes"
  namespace = "${vault_namespace.project.path}"
}

resource "vault_namespace" "cicd" {
  path      = "cicd"
  namespace = "${vault_namespace.project.path}"
}

resource "vault_namespace" "pki_web" {
  path      = "pki-web"
  namespace = "${vault_namespace.project.path}"
}

resource "vault_namespace" "pki_internal" {
  path      = "pki-internal"
  namespace = "${vault_namespace.project.path}"
}

resource "vault_namespace" "cloud" {
  path      = "cloud"
  namespace = "${vault_namespace.project.path}"
}

resource "vault_namespace" "applications" {
  path      = "applications"
  namespace = "${vault_namespace.project.path}"
}

resource "vault_namespace" "ssh" {
  path      = "ssh"
  namespace = "${vault_namespace.project.path}"
}

resource "vault_namespace" "batch" {
  path      = "batch"
  namespace = "${vault_namespace.project.path}"
}

resource "vault_namespace" "encryption" {
  path      = "encryption"
  namespace = "${vault_namespace.project.path}"
}

resource "vault_namespace" "security" {
  path      = "security"
  namespace = "${vault_namespace.project.path}"
}

resource "vault_namespace" "shared" {
  path      = "shared"
  namespace = "${vault_namespace.project.path}"
}

resource "vault_namespace" "x509" {
  path      = "x509"
  namespace = "${vault_namespace.project.path}"
}