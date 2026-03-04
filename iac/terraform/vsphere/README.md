# Terraform (vSphere) — OpenCTI Host Provisioning

This folder contains a **vSphere-only** Terraform configuration that provisions a Linux VM intended to run the OpenCTI Docker Compose stack.

✅ Public-safe: this repository stores **only anonymized examples**.  
❌ Do not commit real credentials, real IPs, SSH private keys, or Terraform state files.

---

## What this creates

- 1x Linux VM on VMware vSphere
- CPU/RAM/Disk configurable
- Network configured (static IP via cloud-init or guest customization — depends on your environment)
- Optional: inject SSH public key for remote access

> Deployment of Docker/OpenCTI is handled separately (e.g., via Ansible). This Terraform layer is only for VM provisioning.

---

## Folder contents

- `main.tf` – resources (VM + customization)
- `variables.tf` – input variables
- `outputs.tf` – VM IP/name outputs (optional)
- `providers.tf` – provider config (vSphere)
- `terraform.tfvars.example` – **example** values (copy and edit locally)

---

## Prerequisites

- Terraform >= 1.5
- Access to a vSphere environment:
  - vCenter URL
  - username/password with permission to create VMs
  - existing template VM (recommended: Ubuntu 22.04/24.04 cloud-init or prepared template)
  - network name/port group

---

## Quick start

### 1) Copy tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
