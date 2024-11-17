terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
  }
  required_version = ">= 0.13"
}
