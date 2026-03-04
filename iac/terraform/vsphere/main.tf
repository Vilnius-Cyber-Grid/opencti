############################################
# Data sources (vSphere inventory lookups)
############################################

data "vsphere_datacenter" "dc" {
  name = var.datacenter_name
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

############################################
# Virtual machine
############################################

resource "vsphere_virtual_machine" "vm" {
  name             = var.vm_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = var.num_cpus
  memory   = var.memory
  guest_id = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks[0].size
    eagerly_scrub    = false
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = var.vm_hostname
        domain    = var.vm_domain
      }

      network_interface {
        ipv4_address = var.ipv4_address
        ipv4_netmask = var.ipv4_netmask
      }

      ipv4_gateway    = var.ipv4_gateway
      dns_server_list = var.dns_server_list
    }
  }
}

############################################
# Optional: add SSH public key to ubuntu user
# NOTE: This requires SSH access to the VM.
# Prefer baking keys into template or using cloud-init.
############################################

resource "null_resource" "ssh_key_setup" {
  count      = var.enable_ssh_key_setup ? 1 : 0
  depends_on = [vsphere_virtual_machine.vm]

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "mkdir -p /home/${var.ssh_user}/.ssh",
      "chmod 700 /home/${var.ssh_user}/.ssh",
      "cat >> /home/${var.ssh_user}/.ssh/authorized_keys << 'EOF'\n${file(var.ssh_public_key_path)}\nEOF",
      "chmod 600 /home/${var.ssh_user}/.ssh/authorized_keys",
      "chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/.ssh"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      password    = var.ssh_password
      private_key = var.ssh_private_key_path != null ? file(var.ssh_private_key_path) : null
      host        = vsphere_virtual_machine.vm.default_ip_address
    }
  }
}

############################################
# Generate Ansible inventory file (optional)
############################################

resource "local_file" "ansible_inventory" {
  count = var.enable_ansible ? 1 : 0

  content = <<EOT
[opencti]
${vsphere_virtual_machine.vm.default_ip_address} ansible_user=${var.ssh_user} ansible_ssh_private_key_file=${var.ssh_private_key_path}
EOT

  filename = "${path.module}/inventory"
}

############################################
# Run Ansible playbook (optional)
############################################

resource "null_resource" "provision_with_ansible" {
  count = var.enable_ansible ? 1 : 0

  depends_on = [
    vsphere_virtual_machine.vm,
    null_resource.ssh_key_setup
  ]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.ansible_inventory[0].filename} ${var.ansible_playbook}"
  }
}
