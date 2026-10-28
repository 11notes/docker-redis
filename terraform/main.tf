terraform {
  required_version = ">= 1.15.0"
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "~> 3.2"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 3.2"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

variable "password" {
  type = string
  sensitive = true
}

locals {
  password = trimspace(var.password)
}

resource "kubernetes_namespace_v1" "redis_namespace" {
  metadata {
    name = "redis"
  }
}

resource "kubernetes_secret_v1" "redis_password" {
  metadata {
    name = "redis-password"
    namespace = "redis"
  }

  data = {
    REDIS_PASSWORD = local.password
  }

  type = "Opaque"
}

resource "helm_release" "redis" {
  name = "redis"
  repository = "oci://ghcr.io/11notes/charts"
  chart = "redis"
  namespace = "redis"
  version = "1.0.1"

  wait = true
  wait_for_jobs = true
  timeout = 300

  values = [
    yamlencode({
      redis = {
        secret = "redis-password"
      }
      persistence = {
        redis = {
          size = "32Gi"
        }
      }
    })
  ]
}