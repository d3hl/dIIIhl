locals {
    proxmox_host   = "192.168.2.11"
    proxmox_node   = "pve11"
    template_vm_id = 9999
}


variable "pve-creds" {
  type=object({
    proxmox_username  =  string
    proxmox_api_token = string
  })
}