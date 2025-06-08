variable "VM_USERNAME" {
  default = "d3" # change me to your username
}
variable "VM_PASSWORD" {
  default = "nLQuNCE4zHAyuMZbmZjn"
}
variable "vm_ssh_key" {
  type = list(string)
  default = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSIn+PaC2XfaYx77fHV/wwCZdi35VZ7ahBaaJwASQ0p"
  ]
}
#variable "proxmox_username" {
#  default = "terra"
#}
#variable "proxmox_api_token" {
#  default = "terra@pve!tf:f2a62bea-f73a-43ec-b92e-77a628fa1f90"
#}

variable "pve-creds" {
  type=object({
    proxmox_username  =  string
    proxmox_api_token = string
  })
  default = {
    proxmox_username  = "terra" 
    proxmox_api_token = "terra@pve!tf=f2a62bea-f73a-43ec-b92e-77a628fa1f90"
    
  }
}