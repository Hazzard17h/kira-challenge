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
  private_key = "${file(var.private_key_file)}"
  token       = "${random_string.token_id.result}.${random_string.token_secret.result}"
  config_file = "/etc/kubernetes/kubeadm-config.yaml"
  nodes       = join(",", concat([ var.master ], var.workers[*]))
}

# Init master node
resource "null_resource" "master" {
  triggers = {
    node = var.master
  }

  connection {
    host        = var.master
    user        = var.user
    private_key = local.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm reset --force",
      "sudo sed -i 's/###TOKEN###/${local.token}/' '${local.config_file}'",
      "sudo kubeadm init --config '${local.config_file}' --node-name master",
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
    user        = var.user
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
    command = "scp -q -i \"${var.private_key_file}\" ${var.user}@${var.master}:.kube/config .kube.config >/dev/null"
  }
}
