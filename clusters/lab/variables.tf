###########################
## OCP Cluster Vars

variable "cluster_slug" {
  type = string
}

variable "vmware_folder" {
  type = string
}

variable "bootstrap_complete" {
  type    = string
  default = "false"
}
################
## VMware vars - unlikely to need to change between releases of OCP

variable "rhcos_template" {
  type = string
}

provider "vsphere" {
  user           = "administrator@vmware.local"
  password       = "XXXXXXX"
  vsphere_server = "192.168.1.98"
  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "datacenter1"
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore1" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

#data "vsphere_compute_cluster" "cluster" {
#  name          = "ocp47"
#  datacenter_id = data.vsphere_datacenter.dc.id
#}

##########
## Ignition

provider "ignition" {
  # https://www.terraform.io/docs/providers/ignition/index.html
  version = "1.2.1"
}

variable "ignition" {
  type    = string
  default = ""
}

#########
## Machine variables

variable "bootstrap_ignition_path" {
  type    = string
  default = ""
}

variable "master_ignition_path" {
  type    = string
  default = ""
}

variable "worker_ignition_path" {
  type    = string
  default = ""
}

variable "master_ips" {
  type    = list(string)
  default = []
}

variable "worker_ips" {
  type    = list(string)
  default = []
}

variable "bootstrap_ip" {
  type    = string
  default = ""
}

variable "loadbalancer_ip" {
  type    = string
  default = ""
}

variable "coredns_ip" {
  type    = string
  default = ""
}

variable "cluster_domain" {
  type = string
}

variable "machine_cidr" {
  type = string
}

variable "gateway" {
  type = string
}

variable "local_dns" {
  type = string
}

variable "public_dns" {
  type = string
}

variable "netmask" {
  type = string
}
