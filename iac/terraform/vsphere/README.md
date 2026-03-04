Terraform (vSphere) — OpenCTI Host Provisioning

This folder contains a vSphere-only Terraform configuration that provisions a Linux VM intended to run the OpenCTI Docker Compose stack.

Public repository safety

This repository stores only anonymized examples

Do not commit real credentials, real IPs, SSH private keys, or Terraform state files

What This Creates

This Terraform configuration provisions:

1 Linux VM on VMware vSphere

Configurable CPU, RAM, and disk

Network configuration using vSphere guest customization

Optional SSH key injection

Deployment of Docker/OpenCTI is handled separately (for example via Ansible or Docker Compose).
Terraform in this directory is responsible only for infrastructure provisioning.

Folder Contents

main.tf — VM resources and configuration

variables.tf — Terraform input variables

providers.tf — vSphere provider configuration

outputs.tf — optional VM outputs (IP, hostname)

terraform.tfvars.example — example configuration values

Prerequisites

Before running Terraform ensure you have:

Terraform >= 1.5

Access to a VMware vSphere environment

Permissions in vCenter to create virtual machines

An existing VM template (recommended: Ubuntu 22.04 / 24.04)

Typical environment components:

vCenter Server

Datacenter

Compute Cluster

Datastore

Network / Port Group

VM Template

Quick Start
1. Copy Example Configuration
cp terraform.tfvars.example terraform.tfvars
2. Edit Configuration

Open terraform.tfvars and update the values for your environment.

Important variables include:

vsphere_server

datacenter_name

cluster_name

datastore_name

network_name

template_name

VM resources (num_cpus, memory)

Network settings (ipv4_address, ipv4_gateway, dns_server_list)

SSH configuration

Example:

vsphere_server  = "vcenter.example.local"
datacenter_name = "DC1"
cluster_name    = "CLUSTER1"
datastore_name  = "DATASTORE1"
network_name    = "VM Network"
3. Initialize Terraform
terraform init
4. Review the Execution Plan
terraform plan
5. Apply the Configuration
terraform apply

Terraform will prompt for confirmation before creating resources.

Security Guidelines

Never commit the following files to the repository:

.terraform/

terraform.tfstate

terraform.tfstate.*

terraform.tfvars

SSH private keys (id_rsa, *.pem, *.key)

passwords or API tokens

Example .gitignore rules:

.terraform/
*.tfstate
*.tfstate.*
*.tfvars
!terraform.tfvars.example

id_rsa
*.pem
*.key
Using Environment Variables for Credentials (Recommended)

Instead of storing credentials in files, you can export them locally:

export TF_VAR_vsphere_user="username"
export TF_VAR_vsphere_password="password"
export TF_VAR_vsphere_server="vcenter.example.local"
