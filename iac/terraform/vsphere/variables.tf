############################################
# vSphere connection
############################################

variable "vsphere_server" {
  description = "vCenter server address or FQDN (e.g., vcenter.example.local)"
  type        = string
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
  sensitive   = true
  default     = null
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
  default     = null
}

############################################
# vSphere inventory objects
############################################

variable "datacenter_name" {
  description = "vSphere datacenter name"
  type        = string
}

variable "cluster_name" {
  description = "vSphere compute cluster name"
  type        = string
}

variable "datastore_name" {
  description = "vSphere datastore name"
  type        = string
}

variable "network_name" {
  description = "vSphere port group / network name"
  type        = string
}

variable "template_name" {
  description = "VM template name to clone from"
  type        = string
}

############################################
# VM configuration
############################################

variable "vm_name" {
  description = "Name of the VM to create"
  type        = string
}

variable "num_cpus" {
  description = "Number of vCPUs"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

############################################
# Network configuration (guest customization)
############################################

variable "ipv4_address" {
  description = "Static IPv4 address to set on the VM"
  type        = string
}

variable "ipv4_netmask" {
  description = "IPv4 netmask bits (e.g., 24)"
  type        = number
}

variable "ipv4_gateway" {
  description = "IPv4 default gateway"
  type        = string
}

variable "dns_server_list" {
  description = "List of DNS servers"
  type        = list(string)
  default     = []
}

############################################
# SSH / provisioning
############################################

variable "ssh_user" {
  description = "SSH username used for provisioning (e.g., ubuntu)"
  type        = string
  default     = "ubuntu"
}

variable "ssh_password" {
  description = "SSH password (NOT recommended). Prefer SSH keys."
  type        = string
  sensitive   = true
  default     = null
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key used by Ansible/inventory (example only; do not commit keys)"
  type        = string
  default     = null
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key (optional)"
  type        = string
  default     = null
}

variable "ansible_playbook" {
  description = "Path to Ansible playbook to run after provisioning"
  type        = string
  default     = null
}
