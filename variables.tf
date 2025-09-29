variable "rg_name" {
  type = string
}
variable "location" {
  type = string
}
variable "public_ip_id" {
  type        = string
  description = "ID de l'IP publique pour le frontend du LB externe"
}
variable "public_vm_nics" {
  description = "Liste des NIC IDs des VMs à mettre derrière le LB externe"
  type        = map(string)
}
variable "internal_vm_nics" {
  description = "Liste des NIC IDs des VMs à mettre derrière le LB interne"
  type        = map(string)
}
variable "internal_subnet_id" {
  description = "Subnet ID où placer le frontend du LB interne"
  type        = string
}

variable "internal_lb_name" {
  type = string
}
variable "tags" {
  type = map(string)
  default = {
    "module" = "loadbalancing"
  }
}
