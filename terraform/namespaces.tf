data "vault_namespace" "admin" {
  path = "admin"
}

resource "vault_namespace" "databases" {
  path      = "databases"
  namespace = "admin/${vault_namespace.project.path}"
}

resource "vault_namespace" "project" {
  path      = var.project_namespace
  namespace = "admin"
}

resource "vault_namespace" "kubernetes" {
  path      = "kubernetes"
  namespace = "admin/${vault_namespace.project.path}"
}

resource "vault_namespace" "cicd" {
  path      = "cicd"
  namespace = "admin/${vault_namespace.project.path}"
}

resource "vault_namespace" "pki_web" {
  path      = "pki-web"
  namespace = "admin/${vault_namespace.project.path}"
}

resource "vault_namespace" "pki_internal" {
  path      = "pki-internal"
  namespace = "admin/${vault_namespace.project.path}"
}

resource "vault_namespace" "cloud" {
  path      = "cloud"
  namespace = "admin/${vault_namespace.project.path}"
}

resource "vault_namespace" "applications" {
  path      = "applications"
  namespace = "admin/${vault_namespace.project.path}"
}

resource "vault_namespace" "ssh" {
  path      = "ssh"
  namespace = "admin/${vault_namespace.project.path}"
}

resource "vault_namespace" "batch" {
  path      = "batch"
  namespace = "admin/${vault_namespace.project.path}"
}

resource "vault_namespace" "encryption" {
  path      = "encryption"
  namespace = "admin/${vault_namespace.project.path}"
}

resource "vault_namespace" "security" {
  path      = "security"
  namespace = "admin/${vault_namespace.project.path}"
}

resource "vault_namespace" "shared" {
  path      = "shared"
  namespace = "admin/${vault_namespace.project.path}"
}

resource "vault_namespace" "x509" {
  path      = "x509"
  namespace = "admin/${vault_namespace.project.path}"
}