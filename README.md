<!-- BEGIN_TF_DOCS -->
# Load Balancing

This module simulate a module would be created by the SRE/Infrastrucutre team for this architecture.
In this module, we will use to create 2 load balancers, with public ip and health prob for port 80

This is a very easy architecture but we will try to simulate real time IT team working and collaboration with good practice.

- In the testing ENV I open the port 22 in load balancer externe
- Now in the Production ENV, I commented that bloc but added a `BASTION` .

```hcl
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

No requirements.

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm)

## Resources

The following resources are used by this module:

- [azurerm_lb.external](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) (resource)
- [azurerm_lb.internal_lb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) (resource)
- [azurerm_lb_backend_address_pool.external_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) (resource)
- [azurerm_lb_backend_address_pool.internal_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) (resource)
- [azurerm_lb_probe.external_http](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) (resource)
- [azurerm_lb_probe.internal_http](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) (resource)
- [azurerm_lb_rule.http_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) (resource)
- [azurerm_lb_rule.internal_http](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) (resource)
- [azurerm_network_interface_backend_address_pool_association.extenal_assoc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_backend_address_pool_association) (resource)
- [azurerm_network_interface_backend_address_pool_association.internal_assoc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_backend_address_pool_association) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_internal_lb_name"></a> [internal\_lb\_name](#input\_internal\_lb\_name)

Description: n/a

Type: `string`

### <a name="input_internal_subnet_id"></a> [internal\_subnet\_id](#input\_internal\_subnet\_id)

Description: Subnet ID où placer le frontend du LB interne

Type: `string`

### <a name="input_internal_vm_nics"></a> [internal\_vm\_nics](#input\_internal\_vm\_nics)

Description: Liste des NIC IDs des VMs à mettre derrière le LB interne

Type: `map(string)`

### <a name="input_location"></a> [location](#input\_location)

Description: n/a

Type: `string`

### <a name="input_name_external_lb"></a> [name\_external\_lb](#input\_name\_external\_lb)

Description: n/a

Type: `string`

### <a name="input_public_ip_id"></a> [public\_ip\_id](#input\_public\_ip\_id)

Description: ID de l'IP publique pour le frontend du LB externe

Type: `string`

### <a name="input_public_vm_nics"></a> [public\_vm\_nics](#input\_public\_vm\_nics)

Description: Liste des NIC IDs des VMs à mettre derrière le LB externe

Type: `map(string)`

### <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name)

Description: n/a

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_tags"></a> [tags](#input\_tags)

Description: n/a

Type: `map(string)`

Default:

```json
{
  "module": "loadbalancing"
}
```

## Outputs

The following outputs are exported:

### <a name="output_external_lb_details"></a> [external\_lb\_details](#output\_external\_lb\_details)

Description: n/a

### <a name="output_internal_lb_details"></a> [internal\_lb\_details](#output\_internal\_lb\_details)

Description: n/a

## Modules

No modules.

This module created by paul for eductional and preparation for Terraform associate 003 purpous.
<!-- END_TF_DOCS -->