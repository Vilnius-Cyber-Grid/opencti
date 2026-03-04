# Terraform (vSphere) — OpenCTI Host Provisioning

This folder contains a **vSphere-only Terraform configuration** that provisions a Linux VM intended to run the OpenCTI Docker Compose stack.

## Public Repository Safety

- This repository stores **only anonymized examples**
- Do **not** commit real credentials, real IPs, SSH private keys, or Terraform state files

---

## What This Creates

This Terraform configuration provisions:

- 1 Linux VM on VMware vSphere
- Configurable CPU, RAM, and disk
- Network configuration using vSphere guest customization
- Optional SSH key injection

> Deployment of Docker/OpenCTI is handled separately (for example via Ansible or Docker Compose).  
> Terraform in this directory is responsible **only for infrastructure provisioning**.

---

## Folder Contents

- `main.tf` — VM resources and configuration
- `variables.tf` — Terraform input variables
- `providers.tf` — vSphere provider configuration
- `outputs.tf` — optional VM outputs (IP, hostname)
- `terraform.tfvars.example` — example configuration values

---

## Prerequisites

Before running Terraform ensure you have:

- Terraform **>= 1.5**
- Access to a VMware vSphere environment
- Permissions in vCenter to create virtual machines
- An existing VM template (recommended: **Ubuntu 22.04 / 24.04**)

Typical environment components:

- vCenter Server
- Datacenter
- Compute Cluster
- Datastore
- Network / Port Group
- VM Template

---

## Quick Start

### 1. Copy Example Configuration

```bash
cp terraform.tfvars.example terraform.tfvars
