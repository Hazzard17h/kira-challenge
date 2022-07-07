variable "private_key_file" {
  type        = string
  description = "Filename of the private key of a key pair on your local machine. This key pair will allow to connect to the nodes of the cluster with SSH."
  default     = "~/.ssh/id_rsa"
}

variable "user" {
  type        = string
  description = "User to connect to the nodes of the cluster with SSH."
  nullable    = false
}

variable "master" {
  type        = string
  description = "Master node IP."
  nullable    = false
}

variable "workers" {
  type        = list(string)
  description = "Worker nodes IPs."
  nullable    = false
}
