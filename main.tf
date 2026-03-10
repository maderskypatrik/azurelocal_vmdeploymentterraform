terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
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

# azurerm has no data sources for HCI custom locations, images, logical networks,
# or storage containers, so we construct their ARM resource IDs directly.
locals {
  custom_location_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.custom_location_resource_group_name}/providers/Microsoft.ExtendedLocation/customLocations/${var.custom_location_name}"

  vm_image_id = var.is_marketplace_image ? (
    "/subscriptions/${var.subscription_id}/resourceGroups/${var.custom_location_resource_group_name}/providers/Microsoft.AzureStackHCI/marketplaceGalleryImages/${var.image_name}"
    ) : (
    "/subscriptions/${var.subscription_id}/resourceGroups/${var.custom_location_resource_group_name}/providers/Microsoft.AzureStackHCI/galleryImages/${var.image_name}"
  )

  logical_network_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.logical_network_rg_name}/providers/Microsoft.AzureStackHCI/logicalNetworks/${var.logical_network_name}"

  storage_container_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.custom_location_resource_group_name}/providers/Microsoft.AzureStackHCI/storageContainers/${var.storage_container_name}"
}

# --- 0) Arc-enabled machine ---
resource "azurerm_arc_machine" "hybrid_compute_machine" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = "westeurope"
  kind                = "HCI"
}

# ---1) HCI Virtual Machine Instance ---
resource "azurerm_stack_hci_virtual_machine_instance" "vm_instance" {
  arc_machine_id     = azurerm_arc_machine.hybrid_compute_machine.id
  custom_location_id = local.custom_location_id

  hardware_profile {
    v_cpu_count = var.v_cpu_count
    memory_mb   = var.memory_mb
  }

  storage_profile {
    image_reference_id        = local.vm_image_id
    vm_config_storage_path_id = local.storage_container_id

    dynamic "data_disk" {
      for_each = azurerm_stack_hci_virtual_hard_disk.data_vhd
      content {
        id = data_disk.value.id
      }
    }
  }

  network_profile {
    network_interface {
      id = azurerm_stack_hci_network_interface.nic.id
    }
  }

  os_profile {
    admin_username = var.vm_admin_username
    admin_password = var.vm_admin_password
    computer_name  = var.name
  }
}

# --- 2) HCI Network Interface ---
resource "azurerm_stack_hci_network_interface" "nic" {
  name                = "${var.name}-nic"
  resource_group_name = var.resource_group_name
  location            = "westeurope"
  custom_location_id  = local.custom_location_id

  ip_configuration {
    name               = "ipconfig1"
    subnet_id          = local.logical_network_id
    private_ip_address = var.private_ip_address
  }
}

# --- 3) Create Data Disks (VHDX) ---
resource "azurerm_stack_hci_virtual_hard_disk" "data_vhd" {
  for_each            = var.data_disk_params
  name                = "${var.name}-${each.key}-vhd"
  resource_group_name = var.resource_group_name
  location            = "westeurope"
  custom_location_id  = local.custom_location_id
  disk_size_in_gb     = each.value.disk_size_gb
  storage_path_id     = local.storage_container_id
  dynamic_enabled     = true
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "vm_resource_id" {
  value = azurerm_stack_hci_virtual_machine_instance.vm_instance.id
}
