variable "hcloud_token" {
  description = "Hetzner Cloud API token"
}

variable "image" {
  description = "Image to use for the server"
}

variable "server_type" {
  description = "Server type to use, e.g. cx11"
}

variable "location" {
  description = "Location to use, e.g. nbg1 (Nuremberg)"
}

variable "ssh_key_id" {
  description = "SSH key ID to use for the server"
}

variable "playbook_path" {
  description = "Path to the Ansible playbook to run on the server. Must be relative to the current working directory."
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "tls_private_key" "aegae" {
  algorithm = "ED25519"
}

output "tls_private_key_aegae" {
  value     = tls_private_key.aegae.private_key_openssh
  sensitive = true
}
output "tls_public_key_aegae" {
  value     = tls_private_key.aegae.public_key_openssh
  sensitive = true
}

resource "local_file" "private_key" {
  content         = tls_private_key.aegae.private_key_openssh
  filename        = "private_key"
  file_permission = "0400"
}

resource "hcloud_ssh_key" "aegae" {
  name       = "Aegae SSH key"
  public_key = tls_private_key.aegae.public_key_openssh
}

resource "hcloud_server" "aegae" {
  name        = "aegae"
  image       = var.image
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.aegae.name]
}

resource "hcloud_volume" "storage" {
  name      = "aegae-volume"
  size      = 20
  server_id = hcloud_server.aegae.id
  automount = true
  format    = "ext4"
}

resource "ansible_host" "aegae" {
  name   = hcloud_server.aegae.ipv4_address
  groups = ["aegae"]
  variables = {
    ansible_user                 = "root",
    ansible_ssh_private_key_file = local_file.private_key.filename,
    ansible_python_interpreter   = "/usr/bin/python3"
  }
}

output "server_ip" {
  value = hcloud_server.aegae.ipv4_address
}
