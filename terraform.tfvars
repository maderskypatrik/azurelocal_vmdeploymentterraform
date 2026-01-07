# --- Infrastructure & Identity ---
subscription_id                     = "your-azure-subscription-id"
resource_group_name                 = "your-resource-group-name"
custom_location_name                = "your-custom-location-name"
custom_location_resource_group_name = "rg-azuf-euw-p-last-mile-monitoring-service" # Default from your variables.tf [cite: 5]

# --- Network & Image ---
logical_network_name                = "your-logical-network-name"
logical_network_rg_name             = "rg-azuf-euw-p-last-mile-monitoring-service" # Default from your variables.tf [cite: 7]
image_name                          = "your-vm-image-name"
is_marketplace_image                = false # Set to true if using a Marketplace image [cite: 9, 20]

# --- Virtual Machine Instance ---
name                                = "your-vm-name"
vm_admin_username                   = "azureuser" # Default from your variables.tf [cite: 11]
vm_admin_password                   = "your-secure-password" # This is marked as sensitive [cite: 12]
v_cpu_count                         = 2    # Default is 2 [cite: 13]
memory_mb                           = 4096 # Default is 4096 MB [cite: 14]

# --- Network & Storage ---
private_ip_address                  = null # Provide a string IP if needed [cite: 15]
data_disk_params                    = {}   # Leave as {} for no extra disks, or define a map [cite: 16]