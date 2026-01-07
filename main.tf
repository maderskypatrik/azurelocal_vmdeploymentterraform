terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# --- Data Lookups ---
# These blocks take the 'Names' you provide in your variables 
# and find the actual 'Resource IDs' required by the module.

# This is required for resource modules
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azapi_resource" "customlocation" {
  name      = var.custom_location_name
  parent_id = data.azurerm_resource_group.rg.id
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-15"
}

data "azapi_resource" "vm_image" {
  name      = var.image_name
  parent_id = data.azurerm_resource_group.rg.id
  type      = var.is_marketplace_image ? "Microsoft.AzureStackHCI/marketplaceGalleryImages@2023-09-01-preview" : "Microsoft.AzureStackHCI/galleryImages@2023-09-01-preview"
}

data "azapi_resource" "logical_network" {
  name      = var.logical_network_name
  parent_id = data.azurerm_resource_group.rg.id
  type      = "Microsoft.AzureStackHCI/logicalNetworks@2023-09-01-preview"
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.

module "test" {
  source = "../../"

  admin_password        = var.vm_admin_password
  admin_username        = var.vm_admin_username
  custom_location_id    = data.azapi_resource.customlocation.id
  image_id              = data.azapi_resource.vm_image.id
  location              = data.azurerm_resource_group.rg.location
  logical_network_id    = data.azapi_resource.logical_network.id
  name                  = var.name
  resource_group_name   = var.resource_group_name
  data_disk_params      = var.data_disk_params
  memory_mb             = var.memory_mb
  private_ip_address    = var.private_ip_address
  v_cpu_count           = var.v_cpu_count
}

# GET THE VM IDENTITY (Crucial for the Agent)
data "azapi_resource" "vm_instance" {
  type        = "Microsoft.AzureStackHCI/virtualMachineInstances@2023-09-01-preview"
  resource_id = module.az_local_vm.resource_id
}

 # # Optional block to configure a proxy server for your VM
  # http_proxy = "http://username:password@proxyserver.contoso.com:3128"
  # https_proxy = "https://username:password@proxyserver.contoso.com:3128"
  # no_proxy = [
  #     "localhost",
  #     "127.0.0.1"
  # ]
  # trusted_ca = "-----BEGIN CERTIFICATE-----....-----END CERTIFICATE-----"

data "azapi_resource" "vm_instance" {
  type      = "Microsoft.AzureStackHCI/virtualMachineInstances@2023-09-01-preview"
  resource_id = module.az_local_vm_test.resource_id
  
}

/* resource "azapi_resource" "guest_mgmt_extension" {
  type      = "Microsoft.HybridCompute/machines/extensions@2023-10-03-preview"
  name      = "AdminCenter"
  parent_id = data.azapi_resource.vm_instance.id
  location = "westeurope"
  body = {properties = {
    autoUpgradeMinorVersion = false
    publisher               = "Microsoft.AdminCenter"
    type                    = "AdminCenter"
  }}
  
} */

/* resource "azurerm_arc_machine_extension" "admin_center_extension" {
  arc_machine_id       = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.HybridCompute/machines/${var.name}"
  type      = "Microsoft.HybridCompute/machines/extensions@2023-10-03-preview"
  name      = "AdminCenter"
  location = "westeurope"
  publisher               = "Microsoft.AdminCenter"
} */

# INSTALL THE GUEST AGENT
# This is what makes the VM "Arc-managed"
resource "azapi_resource" "guest_agent" {
  type      = "Microsoft.AzureStackHCI/virtualMachineInstances/guestAgents@2023-07-01-preview"
  name      = "default"
  parent_id = data.azapi_resource.vm_instance.id
  body = {
    properties = {
      credentials = {
        username = var.vm_admin_username
        password = var.vm_admin_password
      }
      provisioningAction = "install"
    }
  }
  depends_on = [module.az_local_vm]
}

output "vm_resource_id" {
  description = "The resource ID of the Azure Local VM."
  value       = module.az_local_vm_test.resource_id
  
}

output "vm_resource_id_data" {
  value = data.azapi_resource.vm_instance.id
}