data "vsphere_virtual_machine" "template" {
  name          = var.rhcos_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = "ocp47"
  datacenter_id = data.vsphere_datacenter.dc.id
}

module "master" {
  source    = "../../modules/rhcos-static"
  count     = length(var.master_ips)
  name      = "${var.cluster_slug}-master${count.index + 1}"
  folder    = "${var.vmware_folder}"
  datastore = data.vsphere_datastore.datastore1.id
  disk_size = 16
  memory    = 4096
  num_cpu   = 2
  ignition  = file(var.master_ignition_path)

  resource_pool_id = data.vsphere_resource_pool.pool.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  template         = data.vsphere_virtual_machine.template.id
  thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned

  network      = data.vsphere_network.network.id
  adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]

  cluster_domain = var.cluster_domain
  machine_cidr   = var.machine_cidr
  dns_address    = var.local_dns
  gateway        = var.gateway
  ipv4_address   = var.master_ips[count.index]
  netmask        = var.netmask
}

module "worker" {
  source    = "../../modules/rhcos-static"
  count     = length(var.worker_ips)
  name      = "${var.cluster_slug}-worker${count.index + 1}"
  folder    = "${var.vmware_folder}"
  datastore = data.vsphere_datastore.datastore1.id
  disk_size = 16
  memory    = 2048
  num_cpu   = 1
  ignition  = file(var.worker_ignition_path)

  resource_pool_id = data.vsphere_resource_pool.pool.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  template         = data.vsphere_virtual_machine.template.id
  thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned

  network      = data.vsphere_network.network.id
  adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]

  cluster_domain = var.cluster_domain
  machine_cidr   = var.machine_cidr
  dns_address    = var.local_dns
  gateway        = var.gateway
  ipv4_address   = var.worker_ips[count.index]
  netmask        = var.netmask
}

module "bootstrap" {
  source    = "../../modules/rhcos-static"
  count     = "${var.bootstrap_complete ? 0 : 1}"
  name      = "${var.cluster_slug}-bootstrap"
  folder    = "${var.vmware_folder}"
  datastore = data.vsphere_datastore.datastore1.id
  disk_size = 16
  memory    = 2048
  num_cpu   = 1
  ignition  = file(var.bootstrap_ignition_path)

  resource_pool_id = data.vsphere_resource_pool.pool.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  template         = data.vsphere_virtual_machine.template.id
  thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned

  network      = data.vsphere_network.network.id
  adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]

  cluster_domain = var.cluster_domain
  machine_cidr   = var.machine_cidr
  dns_address    = var.local_dns
  gateway        = var.gateway
  ipv4_address   = var.bootstrap_ip
  netmask        = var.netmask
}

module "lb" {
  source = "../../modules/ignition_haproxy"

  ssh_key_file  = [file("~/.ssh/ocp4.pub")]
  lb_ip_address = var.loadbalancer_ip
  api_backend_addresses = flatten([
    var.bootstrap_ip,
    var.master_ips]
  )
  ingress = var.worker_ips
}

module "lb_vm" {
  source    = "../../modules/rhcos-static"
  count     = 1
  name      = "${var.cluster_slug}-lb"
  folder    = "${var.vmware_folder}"
  datastore = data.vsphere_datastore.datastore1.id
  disk_size = 16
  memory    = 1024
  num_cpu   = 1
  ignition  = module.lb.ignition

  resource_pool_id = data.vsphere_resource_pool.pool.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  template         = data.vsphere_virtual_machine.template.id
  thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned

  network      = data.vsphere_network.network.id
  adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]

  cluster_domain = var.cluster_domain
  machine_cidr   = var.machine_cidr
  dns_address    = var.public_dns
  gateway        = var.gateway
  ipv4_address   = var.loadbalancer_ip
  netmask        = var.netmask
}

# output "ign" {
#   value = module.lb.ignition
# }

module "coredns" {
  source       = "../../modules/ignition_coredns"
  ssh_key_file = [file("~/.ssh/ocp4.pub")]

  cluster_slug    = var.cluster_slug
  cluster_domain  = var.cluster_domain
  coredns_ip      = var.coredns_ip
  bootstrap_ip    = var.bootstrap_ip
  loadbalancer_ip = var.loadbalancer_ip
  master_ips      = var.master_ips
  worker_ips      = var.worker_ips
}

module "dns_vm" {
  source    = "../../modules/rhcos-static"
  count     = 1
  name      = "${var.cluster_slug}-coredns"
  folder    = "${var.vmware_folder}"
  datastore = data.vsphere_datastore.datastore1.id
  disk_size = 16
  memory    = 1024
  num_cpu   = 1
  ignition  = module.coredns.ignition

  resource_pool_id = data.vsphere_resource_pool.pool.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  template         = data.vsphere_virtual_machine.template.id
  thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned

  network      = data.vsphere_network.network.id
  adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]

  cluster_domain = var.cluster_domain
  machine_cidr   = var.machine_cidr
  dns_address    = var.public_dns
  gateway        = var.gateway
  ipv4_address   = var.coredns_ip
  netmask        = var.netmask
}
