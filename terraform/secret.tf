variable "vm_username" {
  default = "d3" # change me to your username
}
variable "vm_password" {
  default = "abcd"
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
variable "proxmox_api_token" {
  default = "terra@pve!tf:f2a62bea-f73a-43ec-b92e-77a628fa1f90"
}

variable "pve-creds" {
  type=object({
    proxmox_username  =  string
    proxmox_api_token = string
  })
  default = {
    proxmox_username  = "" 
    proxmox_api_token = ""
    
  }
}