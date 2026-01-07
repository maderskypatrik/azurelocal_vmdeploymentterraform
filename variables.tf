# --- Infrastructure & Identity Variables ---
variable "subscription_id" {
    description = "The subscription ID where the resources will be created."
    type        = string
  
}
variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group where Azure Local resources are located."
}

variable "custom_location_name" {
  type        = string
  description = "The name of the Custom Location associated with your Azure Local cluster."
}

variable "custom_location_resource_group_name" {
    description = "The name of the resource group where the custom location is defined."
    type        = string
    default     = "rg-azuf-euw-p-last-mile-monitoring-service"
}

variable "logical_network_name" {
  type        = string
  description = "The name of the Logical Network (VLAN/VM Switch) for the VM."
}

variable "logical_network_rg_name" {
    description = "The name of the resource group where the logical network is defined."
    type        = string
    default     = "rg-azuf-euw-p-last-mile-monitoring-service"  
}

variable "image_name" {
  type        = string
  description = "The name of the VM image (Marketplace or Gallery) to use."
}

variable "is_marketplace_image" {
  type        = bool
  default     = false
  description = "Set to true if using a Marketplace image, false if using a custom Gallery image."
}

# --- Virtual Machine Instance Variables ---

variable "name" {
  type        = string
  description = "The name of the Virtual Machine instance."
}

variable "vm_admin_username" {
  type        = string
  default     = "azureuser"
  description = "The local administrator username for the VM."
}

variable "vm_admin_password" {
  type        = string
  sensitive   = true
  description = "The local administrator password for the VM."
}

variable "v_cpu_count" {
  type        = number
  default     = 2
  description = "Number of virtual CPUs."
}

variable "memory_mb" {
  type        = number
  default     = 4096
  description = "Memory size in MB."
}

# --- Network & Storage ---

variable "private_ip_address" {
  type        = string
  default     = null
  description = "The private IP address to assign to the VM."
}

variable "data_disk_params" {
  type = map(object({
    disk_size_gb = number
    storage_path = string
  }))
  default     = {}
  description = "Map of data disks to attach to the VM."
}



