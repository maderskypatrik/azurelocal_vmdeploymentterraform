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
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azapi_resource" "customlocation" {
  name      = var.custom_location_name
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.custom_location_resource_group_name}"
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-15"
}

data "azapi_resource" "vm_image" {
  name      = var.image_name
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.custom_location_resource_group_name}"
  type      = var.is_marketplace_image ? "Microsoft.AzureStackHCI/marketplaceGalleryImages@2023-09-01-preview" : "Microsoft.AzureStackHCI/galleryImages@2023-09-01-preview"
}

data "azapi_resource" "logical_network" {
  name      = var.logical_network_name
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.logical_network_rg_name}"
  type      = "Microsoft.AzureStackHCI/logicalNetworks@2023-09-01-preview"
}

# NEW: Data lookup for the HCI Storage Container
data "azapi_resource" "storage_container" {
  name      = var.storage_container_name
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.custom_location_resource_group_name}"
  type      = "Microsoft.AzureStackHCI/storageContainers@2024-01-01"
}

# --- 0) Arc-enabled machine ---
resource "azapi_resource" "hybrid_compute_machine" {
  type      = "Microsoft.HybridCompute/machines@2023-10-03-preview"
  name      = var.name
  parent_id = data.azurerm_resource_group.rg.id
  location  = "westeurope"

  body = {
    kind       = "HCI"
    properties = {}
  }
}

# --- 1) HCI Network Interface ---
resource "azapi_resource" "nic" {
  type      = "Microsoft.AzureStackHCI/networkInterfaces@2023-09-01-preview"
  name      = "${var.name}-nic"
  parent_id = data.azurerm_resource_group.rg.id
  location  = "westeurope"

  body = {
    extendedLocation = {
      name = data.azapi_resource.customlocation.id
      type = "CustomLocation"
    }
    properties = {
      ipConfigurations = [
        {
          name = "ipconfig1"
          properties = {
            subnet = {
              id = data.azapi_resource.logical_network.id
            }
            privateIPAddress = var.private_ip_address
          }
        }
      ]
    }
  }
}

# --- 1.5) Create Data Disks (VHDX) ---
# We must create the physical disks on the cluster before attaching them
resource "azapi_resource" "data_vhd" {
  for_each  = var.data_disk_params
  type      = "Microsoft.AzureStackHCI/virtualHardDisks@2024-01-01"
  name      = "${var.name}-${each.key}-vhd"
  parent_id = data.azurerm_resource_group.rg.id
  location  = "westeurope"

  body = {
    extendedLocation = {
      name = data.azapi_resource.customlocation.id
      type = "CustomLocation"
    }
    properties = {
      diskSizeGB  = each.value.disk_size_gb
      containerId = data.azapi_resource.storage_container.id
      dynamic     = true # This is standard for HCI to save space
    }
  }
}

# --- 2) HCI Virtual Machine Instance ---
resource "azapi_resource" "vm_instance" {
  type      = "Microsoft.AzureStackHCI/virtualMachineInstances@2024-01-01"
  name      = "default"
  parent_id = azapi_resource.hybrid_compute_machine.id

  #identity {
    #type = "SystemAssigned"
  #}
  schema_validation_enabled = false

  body = {
    extendedLocation = {
      name = data.azapi_resource.customlocation.id
      type = "CustomLocation"
    }
    properties = {
      hardwareProfile = {
        processors = var.v_cpu_count
        memoryMB   = var.memory_mb
      }
      storageProfile = {
        imageReference = {
          id = data.azapi_resource.vm_image.id
        }
        
        # This tells Azure where the VM's configuration files live
        vmConfigStoragePathId = data.azapi_resource.storage_container.id 

        # FIXED: Only provide the ID of the disks we created above
        dataDisks = [
          for k, v in azapi_resource.data_vhd : {
            id = v.id
          }
        ]
      }
      networkProfile = {
        networkInterfaces = [{ id = azapi_resource.nic.id }]
      }
      osProfile = {
        adminUsername = var.vm_admin_username
        adminPassword = var.vm_admin_password
        computerName  = var.name
      }
    }
  }
}


# --- 2.1) Enable Guest Management (installs the in-guest agent) ---
# API version: use the latest preview that exposes the guestAgents child resource.
# As of now, 2025-09-01-preview (or 2026-02-01-preview) are documented.
#resource "azapi_resource" "guest_agent" {
#  type      = "Microsoft.AzureStackHCI/virtualMachineInstances/guestAgents@2025-04-01-preview"
#  name      = "default"
#  parent_id = azapi_resource.vm_instance.id
#
# (Optional) Terraform will already infer dependency via parent_id,
# but you can be explicit if you like:
# depends_on = [azapi_resource.vm_instance]
#
# body = {
#   properties = {
#     provisioningAction = "install"
#     credentials = {
#       # Reuse the same local admin you already set in osProfile
#       username = var.vm_admin_username
#       password = var.vm_admin_password
#     }
#   }
# }
#}


# -----------------------------------------------------------------------------
# 3) (Optional) Install HCI Guest Agent on the VM
# -----------------------------------------------------------------------------
#
# resource "azapi_resource" "guest_agent" {
# type      = "Microsoft.AzureStackHCI/virtualMachineInstances/guestAgents@2024-01-01"
# name      = "default"
# parent_id = azapi_resource.vm_instance.id
# 
# schema_validation_enabled = false
# 
# body = {
#   properties = {
#     credentials = {
#       username = var.vm_admin_username
#       password = var.vm_admin_password
#     }
#     provisioningAction = "install"
#   }
# }
#}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "vm_resource_id" {
  value = azapi_resource.vm_instance.id
}
