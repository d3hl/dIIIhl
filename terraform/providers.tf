terraform {
  cloud {
    organization = "ncdv_org"
    hostname = ""
    workspaces {
      name = "dIIIhl"
      project = "k8s"
  }
  }
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.73.1"
    }
  }
}
provider "proxmox" {
  endpoint   = "https://${local.proxmox_host}:8006/api2/json"
  api_token  = var.pve-creds.proxmox_api_token
  ssh {
    username = var.pve-creds.proxmox_username
    agent    = true
  }
  insecure   = true
}
