terraform {
  required_providers {
    metal = {
      version = "~> 3.2.2"
      source  = "equinix/metal"
    }
  }
}

## VARIABLES

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "liquid-metal-demo"
}

variable "org_id" {
  description = "Org id"
  type        = string
}

variable "metro" {
  description = "Metro to create resources in"
  type        = string
  default     = "am"
}

variable "server_type" {
  description = "The type/plan to use for devices"
  type        = string
  default     = "c3.small.x86"
  validation {
    condition = contains([
      "c3.small.x86",
      "m3.small.x86",
      "c3.medium.x86",
      ],
    var.server_type)
    error_message = "Disallowed instance type."
  }
}

variable "host_device_count" {
  description = "number of flintlock hosts to create"
  type        = number
  default     = 2
  validation {
    condition     = max(var.host_device_count) == 3
    error_message = "Too many hosts requested."
  }
}

variable "metal_auth_token" {
  description = "Auth token"
  type        = string
  sensitive   = true
}

variable "ts_auth_key" {
  description = "Auth key for tailscale vpn"
  type        = string
  sensitive   = true
}

variable "public_key" {
  description = "public key to add to hosts"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "the path to the private key to use for SSH"
  type        = string
}

variable "flintlock_version" {
  description = "the version of flintlock to provision hosts with (default: latest)"
  type        = string
}

variable "firecracker_version" {
  description = "the version of firecracker to provision hosts with (default: latest)"
  type        = string
}

## THE JUICE

provider "metal" {
  auth_token = var.metal_auth_token
}

# Create new project
resource "metal_project" "liquid_metal_demo" {
  name            = var.project_name
  organization_id = var.org_id
}

# Add SSH key
resource "metal_project_ssh_key" "demo_key" {
  name       = "liquid-metal-demo-key"
  public_key = var.public_key
  project_id = metal_project.liquid_metal_demo.id
}

# Create VLAN in project
resource "metal_vlan" "vlan" {
  description = "VLAN for liquid-metal-demo"
  metro       = var.metro
  project_id  = metal_project.liquid_metal_demo.id
}

# Create device for dhcp, nat routing, vpn etc
resource "metal_device" "dhcp_nat" {
  hostname            = "dhcp-nat"
  plan                = var.server_type
  metro               = var.metro
  operating_system    = "ubuntu_20_04"
  billing_cycle       = "hourly"
  user_data           = "#!/bin/bash\ncurl -s https://raw.githubusercontent.com/masters-of-cats/a-new-hope/main/install.sh | bash -s"
  project_ssh_key_ids = [metal_project_ssh_key.demo_key.id]
  project_id          = metal_project.liquid_metal_demo.id
}

# Update the dhcp device networking to be Hybrid-Bonded with VLAN attached
resource "metal_port" "bond0_dhcp" {
  port_id  = [for p in metal_device.dhcp_nat.ports : p.id if p.name == "bond0"][0]
  layer2   = false
  bonded   = true
  vlan_ids = [metal_vlan.vlan.id]
}

# Create N devices to act as flintlock hosts
resource "metal_device" "host" {
  count               = var.host_device_count
  hostname            = "host-${count.index}"
  plan                = var.server_type
  metro               = var.metro
  operating_system    = "ubuntu_20_04"
  billing_cycle       = "hourly"
  user_data           = "#!/bin/bash\ncurl -s https://raw.githubusercontent.com/masters-of-cats/a-new-hope/main/install.sh | bash -s"
  project_ssh_key_ids = [metal_project_ssh_key.demo_key.id]
  project_id          = metal_project.liquid_metal_demo.id
}

# Update the host devices' networking to be Hybrid-Bonded with VLAN attached
resource "metal_port" "bond0_host" {
  count    = var.host_device_count
  port_id  = [for p in metal_device.host[count.index].ports : p.id if p.name == "bond0"][0]
  layer2   = false
  bonded   = true
  vlan_ids = [metal_vlan.vlan.id]
}

# Set up the vlan, dhcp server, nat routing and the vpn on the dhcp_nat device
resource "null_resource" "setup_dhcp_nat" {
  connection {
    type        = "ssh"
    host        = metal_device.dhcp_nat.network.0.address
    user        = "root"
    port        = 22
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "files/vlan.sh"
    destination = "/root/vlan.sh"
  }

  provisioner "file" {
    source      = "files/dhcp.sh"
    destination = "/root/dhcp.sh"
  }

  provisioner "file" {
    source      = "files/nat.sh"
    destination = "/root/nat.sh"
  }

  provisioner "file" {
    source      = "files/tailscale.sh"
    destination = "/root/tailscale.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /root/vlan.sh",
      "chmod +x /root/dhcp.sh",
      "chmod +x /root/nat.sh",
      "chmod +x /root/tailscale.sh",
      "VLAN_ID=${metal_vlan.vlan.vxlan} ADDR=2 /root/vlan.sh",
      "VLAN_ID=${metal_vlan.vlan.vxlan} /root/dhcp.sh",
      "VLAN_ID=${metal_vlan.vlan.vxlan} /root/nat.sh",
      "AUTH_KEY=${var.ts_auth_key} /root/tailscale.sh",
    ]
  }
}

# Set up the vlan and configure flintlock on the hosts
resource "null_resource" "setup_hosts" {
  count = var.host_device_count
  connection {
    type        = "ssh"
    host        = metal_device.host[count.index].network.0.address
    user        = "root"
    port        = 22
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "files/vlan.sh"
    destination = "/root/vlan.sh"
  }

  provisioner "file" {
    source      = "files/flintlock.sh"
    destination = "/root/flintlock.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /root/vlan.sh",
      "chmod +x /root/flintlock.sh",
      "VLAN_ID=${metal_vlan.vlan.vxlan} ADDR=${count.index + 3} /root/vlan.sh",
      "VLAN_ID=${metal_vlan.vlan.vxlan} FLINTLOCK=${var.flintlock_version} FIRECRACKER=${var.firecracker_version} /root/flintlock.sh",
    ]
  }
}
