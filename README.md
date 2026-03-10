# Azure Local VM Deployment Guide
This repository contains the Terraform configuration and GitHub Actions workflow required to deploy and manage Virtual Machines on Azure Local (Azure Stack HCI) via the azapi provider

## Deployment Overview
The configuration automates the creation of a complete VM environment on your local cluster:

Identity: Creates an Arc-enabled machine resource to represent the VM in the Azure Portal.

Networking: Configures a Network Interface (NIC) attached to a specific Logical Network/VLAN.

Storage: Provisions dynamic VHDX data disks on a designated HCI Storage Container.

Instance: Sets up the VM with defined CPU, memory, and OS credentials.

## Prerequisites
Before deploying, ensure you have the following information from your Azure Local administrator:

Custom Location: The name of the CustomLocation resource representing your cluster.

Logical Network: The name of the VLAN/VM Switch.

Storage Container: The name of the Cluster Volume where disks will be stored.

Image: The name of a pre-downloaded Marketplace or Gallery image.

## Variables Reference
To deploy a VM, update your terraform.tfvars file with these parameters:

| Variable	| Description	| Example Value |
|-----------|-------------|---------------|
|subscription_id|Azure Subscription ID for the resources.|e03b2341-...|
|resource_group_name|RG where the VM resources will be placed.|PowerCo-AzureLocal-RG|
|name|The hostname and resource name for the VM.|azulo-vm-dev001|
|custom_location_name|The name of your Azure Local Custom Location.|LDR01-SZ|
|custom_location_rg|RG where the custom location is defined.|rg-Azurelocal-mgmt|
|logical_network_name|The name of the VLAN/Network for the VM.|VLAN625|
|logical_network_rg|RG where the logical network is defined.|rg-Azurelocal-mgmt|
|private_ip_address|(Optional) Static IP for the VM.|10.9.63.248|
|image_name|The name of the VM image to use.|Ubunutt2204Image|
|storage_container|HCI Storage Container name for disks.|UserStorage1-...|
|v_cpu_count|Number of virtual CPUs.|2|
|memory_mb|Memory size in MB.|4096|
|vm_admin_username|Local administrator username.|NameSurname_Company|
|vm_admin_password|Sensitive Local admin password.|********|

## How to Deploy
### 1. Local Deployment
Clone the Repo.

Configure Vars: Update terraform.tfvars with your specific values.

Run Terraform:

terraform init

terraform plan

terraform apply

### 2. Automated Deployment (GitHub Actions)
This project includes a CI/CD pipeline in deploy.yml. To use it:

GitHub Secrets: Add your Azure Service Principal details (AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID) to repository secrets.

VM Password: Add VM_ADMIN_PASSWORD as a secret. The workflow automatically maps this to the Terraform variable TF_VAR_vm_admin_password.

Push to Main: Any push to the main branch will trigger an automatic terraform apply.

## Important Notes
Security: The vm_admin_password is marked as sensitive in Terraform. It will not be printed in console outputs or logs.

Region: Resources are currently deployed to the westeurope region by default in the main.tf file.

Data Disks: You can add additional disks by modifying the data_disk_params map in your .tfvars file.

Guest Management: If you deploy Linux VM, it wont have Guest Management enabled. It's currently known limitation. (https://github.com/DellGEOS/AzureLocalHOLs/blob/main/tips%26tricks/09-PullingImageFromAzure/readme.md)
