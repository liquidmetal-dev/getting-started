module "create_devices" {
  source  = "weaveworks-liquidmetal/liquidmetal/equinix"
  version = "0.0.1"

  project_name = var.project_name
  public_key = var.public_key
  org_id = var.org_id
  metal_auth_token = var.metal_auth_token
  microvm_host_device_count = var.microvm_host_device_count
  bare_metal_device_count = var.bare_metal_device_count
  # metro = "fr"
  # server_type = "c3.small.x86"
  # operating_system = "ubuntu_20_04"
}

module "provision_hosts" {
  source  = "weaveworks-liquidmetal/liquidmetal/equinix//modules/provision"
  version = "0.0.1"

  ts_auth_key = var.ts_auth_key
  private_key_path = var.private_key_path
  vlan_id = module.create_devices.vlan_id
  network_hub_address = module.create_devices.network_hub_ip
  microvm_host_addresses = module.create_devices.microvm_host_ips
  baremetal_host_addresses = module.create_devices.bare_metal_host_ips
  microvm_host_device_count = var.microvm_host_device_count
  bare_metal_device_count = var.bare_metal_device_count
  # flintlock_version = "latest"
  # firecracker_version = "latest"
}

# required variables pulled from terraform.tfvars.json
variable "project_name" {
  description = "Project name"
  type        = string
}

variable "org_id" {
  description = "Org id"
  type        = string
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
}

variable "private_key_path" {
  description = "the path to the private key to use for SSH"
  type        = string
  sensitive   = true
}

# optional variables with defaults
variable "microvm_host_device_count" {
  description = "The number of devices to provision as flintlock hosts."
  type        = number
  default     = 2
}

variable "bare_metal_device_count" {
  description = "The number of devices to provision as bare metal hosts."
  type        = number
  default     = 0
}

# useful outputs to print
output "network_hub_ip" {
  value = module.create_devices.network_hub_ip
  description = "The address of the device created to act as a networking configuration hub"
}

output "microvm_host_ips" {
  value = module.create_devices.microvm_host_ips
  description = "The addresses of the devices provisioned as flintlock microvm hosts"
}

output "bare_metal_host_ips" {
  value = module.create_devices.bare_metal_host_ips
  description = "The addresses of the devices provisioned as baremetal hosts"
}
