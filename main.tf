##################This module will contain load balacing resources########################
###############This is a external load balancer with a public IP ######################
resource "azurerm_lb" "external" {
  name                = var.name_external_lb
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "PublicFrontend"
    public_ip_address_id = var.public_ip_id
  }
}

# 2. Backend Address Pool (vide pour l'instant)
resource "azurerm_lb_backend_address_pool" "external_pool" {
  loadbalancer_id = azurerm_lb.external.id
  name            = "ExternalBackendPool"

}

# 3. Health Probe (HTTP sur port 80)
resource "azurerm_lb_probe" "external_http" {
  loadbalancer_id     = azurerm_lb.external.id
  name                = "http-probe"
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 30
  number_of_probes    = 2
}
###############I use this for testing env but now we have bastion so dont need this#####################
# resource "azurerm_lb_probe" "ssh_probe" {
#   loadbalancer_id     = azurerm_lb.external.id
#   name                = "ssh-probe"
#   protocol            = "Tcp"
#   port                = 22
#   interval_in_seconds = 30
#   number_of_probes    = 2
# }

# 4. Load Balancing Rule
resource "azurerm_lb_rule" "http_rule" {
  loadbalancer_id                = azurerm_lb.external.id
  name                           = "HTTP-LB-Rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicFrontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.external_pool.id]
  probe_id                       = azurerm_lb_probe.external_http.id
  disable_outbound_snat          = false # Optionnel, mais recommandé pour éviter SNAT inutile

}
###################I use this for testing env but now we have bastion so dont need this#########################
# resource "azurerm_lb_rule" "ssh_rule" {
#   loadbalancer_id                = azurerm_lb.external.id
#   name                           = "SSH-LB-Rule"
#   protocol                       = "Tcp"
#   frontend_port                  = 22               # ← Exposé publiquement
#   backend_port                   = 22               # ← Port SSH sur ta VM
#   frontend_ip_configuration_name = "PublicFrontend" # ← Doit correspondre au nom dans ton LB frontend config
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.external_pool.id]
#   probe_id                       = azurerm_lb_probe.ssh_probe.id
#   disable_outbound_snat          = false
# }

# 5. Associer la NIC de ta VM au backend pool
resource "azurerm_network_interface_backend_address_pool_association" "extenal_assoc" {
  for_each = var.public_vm_nics

  network_interface_id    = each.value
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.external_pool.id
}

###
### Internal LB ###
# Load Balancer Interne

resource "azurerm_lb" "internal_lb" {
  name                = var.internal_lb_name
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                          = "InternalFrontend"
    private_ip_address_allocation = "Dynamic" # IP privée dynamique dans le subnet
    subnet_id                     = var.internal_subnet_id
  }
}

# Backend Pool (pour VM2)
resource "azurerm_lb_backend_address_pool" "internal_pool" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name            = "InternalBackendPool"
}

# Health Probe (HTTP sur port 80 de VM2)
resource "azurerm_lb_probe" "internal_http" {
  loadbalancer_id     = azurerm_lb.internal_lb.id
  name                = "http-probe"
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 30
  number_of_probes    = 2
}
# Règle de Load Balancing : écoute sur port 80, redirige vers port 80 de VM2
resource "azurerm_lb_rule" "internal_http" {
  loadbalancer_id                = azurerm_lb.internal_lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "InternalFrontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.internal_pool.id]
  probe_id                       = azurerm_lb_probe.internal_http.id
  disable_outbound_snat          = false
}

# Associer VM2 au backend pool
resource "azurerm_network_interface_backend_address_pool_association" "internal_assoc" {
  for_each = var.internal_vm_nics

  network_interface_id    = each.value
  ip_configuration_name   = "ipconfig1" # Nom de la config IP dans ta NIC (souvent "ipconfig")
  backend_address_pool_id = azurerm_lb_backend_address_pool.internal_pool.id
}
