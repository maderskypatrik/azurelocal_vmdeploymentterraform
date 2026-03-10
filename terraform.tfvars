subscription_id                     = "e03b2341-ad4b-4989-9f96-78605b8d0645" 
resource_group_name                 = "PowerCo-AzureLocal-POC-PatrikUbunutImagePOC-RG" 
logical_network_name                = "VLAN625" 
logical_network_rg_name             = "rg-Azurelocal-mgmt" 
private_ip_address                  = "10.9.63.248" 
name                                = "azulo-vm-ubuntu01"
vm_admin_username                   = "PatrikMadersky_Trask" 
vm_admin_password                   = "Malenovice227!" # This is marked as sensitive
v_cpu_count                         = 2 #Number of vCPUs 
memory_mb                           = 4096 #Memory
image_name                          = "Ubunutt2204Image" 
custom_location_name                = "LDR01-SZ" 
custom_location_resource_group_name = "rg-azurelocal-mgmt" 

# NEW: Provide your HCI cluster storage container name
storage_container_name              = "UserStorage2-2a8bdf22d0c44ebbb6abe2eb40ad434e" #Use UserStorage1-6058a70f8df44d5aa3c681597e021441 or UserStorage2-2a8bdf22d0c44ebbb6abe2eb40ad434e

# NEW: Example data disk configuration
data_disk_params = {
  "disk1" = {
    disk_size_gb = 32 #Disk Space
  }
}
