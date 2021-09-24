## Node IPs
loadbalancer_ip = "192.168.1.201"
coredns_ip = "192.168.1.202"
bootstrap_ip = "192.168.1.200"
master_ips = ["192.168.1.203"]
worker_ips = ["192.168.1.204"]

## Cluster configuration
vmware_folder = "ocp47"
rhcos_template = "rhcos-4.7.7"
cluster_slug = "ocp47"
cluster_domain = "openshift.lab.int"
machine_cidr = "192.168.1.0/24"
netmask ="255.255.255.0"

## DNS
local_dns = "192.168.1.202" # probably the same as coredns_ip
public_dns = "1.1.1.1" # e.g. 1.1.1.1
gateway = "192.168.1.1"

## Ignition paths
## Expects `openshift-install create ignition-configs` to have been run
## probably via generate-configs.sh
bootstrap_ignition_path = "../../openshift/bootstrap.ign"
master_ignition_path = "../../openshift/master.ign"
worker_ignition_path = "../../openshift/worker.ign"

