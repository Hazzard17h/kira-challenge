terraform {
  required_version = ">= 0.12"
}

# Generate bootstrap token
resource "random_string" "token_id" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "token_secret" {
  length  = 16
  special = false
  upper   = false
}

locals {
  host_user   = "ubuntu"
  private_key = "${file(var.private_key_file)}"
  token       = "${random_string.token_id.result}.${random_string.token_secret.result}"
  nodes       = join(",", concat([ var.master ], var.workers[*]))
}

# Init master node
resource "null_resource" "master" {
  triggers = {
    node = var.master
  }

  connection {
    host        = var.master
    user        = local.host_user
    private_key = local.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm reset --force",
      "sudo kubeadm init --control-plane-endpoint ${var.master}:6443 --token '${local.token}' --node-name master",
      "mkdir -p $HOME/.kube",
      "sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
    ]
  }
}

# Join worker nodes
resource "null_resource" "worker" {
  for_each = toset(var.workers)

  triggers = {
    node = each.value
  }

  depends_on = [
    null_resource.master
  ]

  connection {
    host        = each.value
    user        = local.host_user
    private_key = local.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm reset --force",
      "sudo kubeadm join ${var.master}:6443 --token '${local.token}' --node-name 'worker${index(var.workers, each.value) + 1}' --discovery-token-unsafe-skip-ca-verification"
    ]
  }
}

# Download kubeconfig
resource "null_resource" "download_kubeconfig_file" {
  triggers = {
    nodes  = local.nodes
  }

  depends_on = [
    null_resource.master
  ]

  provisioner "local-exec" {
    command = "scp -q -i ${var.private_key_file} ${local.host_user}@${var.master}:.kube/config .kube.config >/dev/null"
  }
}

# Create K8S namespace
provider "kubernetes" {
  config_path = ".kube.config"
}

resource "kubernetes_namespace" "kiratech-test" {
  depends_on = [
    null_resource.download_kubeconfig_file
  ]

  metadata {
    name = "kiratech-test"
  }
}

# Run kube-bench on master node
resource "null_resource" "kube-bench" {
  triggers = {
    nodes  = local.nodes
  }

  depends_on = [
    null_resource.download_kubeconfig_file
  ]

  connection {
    host        = var.master
    user        = local.host_user
    private_key = local.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro -t docker.io/aquasec/kube-bench:latest --version $(kubectl version --short  | sed -En \"/Server Version/ s/.*: v([0-9]+\\.[0-9]+).*/\\1/p\")"
    ]
  }
}
