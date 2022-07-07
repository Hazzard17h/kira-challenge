terraform {
  required_version = ">= 0.12"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

locals {
  user = "ubuntu"
}

# Cluster provisioning
module "cluster" {
  source = "./modules/cluster"

  private_key_file = var.private_key_file
  user             = local.user
  master           = var.master
  workers          = var.workers
}

# Create K8S namespace
provider "kubernetes" {
  config_path = ".kube.config"
}

resource "kubernetes_namespace" "kiratech-test" {
  depends_on = [
    module.cluster
  ]

  metadata {
    name = "kiratech-test"
  }
}

# Run kube-bench on master node
resource "null_resource" "kube-bench" {
  triggers = {
    node  = var.master
  }

  depends_on = [
    module.cluster
  ]

  connection {
    host        = var.master
    user        = local.user
    private_key = "${file(var.private_key_file)}"
  }

  provisioner "remote-exec" {
    inline = [
      "docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro -t docker.io/aquasec/kube-bench:latest --version $(kubectl version --short  | sed -En \"/Server Version/ s/.*: v([0-9]+\\.[0-9]+).*/\\1/p\")"
    ]
  }
}
