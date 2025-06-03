module "k8s" {
  source = "./prod/talos-k8s"
  talos-common = var.talos-common
  credentials = var.credentials
  talos_ips = var.talos_ips
#  pveuser = var.credentials.pveuser
#  pvepassword = var.credentials.pvepassword 
#  api_token= var.credentials.api_token
  #credentials = var.credentials.endpoint
  #pveuser = var.pveuser
  #endpoint = var.endpoint
  #pvepassword = var.pvepassword
  #api_token = var.api_token
  }