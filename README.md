## Deploy Openshift 4 for VMWare via Terraform. 

Note: It focuses on UPI with vSphere 6.7u3. The code here is working against OCP 4.7.

### Pre-reqs

#### VMware vSphere environment install/setup requirements

Install ESXi 6.7/7 server(s), deploy VMware vCenter Server Appliance  6.7/7 (VCSA) as ESXi VM, create datacenter and add ESXi hosts to it.

Note: VMWare vSphere environment has been deployed on HP server for this demo and used ISO files are:

* VMware_ESXi_6.7.0_17700523_HPE_Gen9plus_670.U3.10.7.0.132_May2021.iso (for ESXi installation)
* VMware-VCSA-all-6.7.0-17138064.iso (for VCSA deploy)


#### Local system requirements (laptop/workstation)

To be able to apply this Terraform configuration to your vSphere environment, make sure you have to following requirements in place. Basically all you need are git, for cloning the github repo and the Terraform binary to run the playbook.

Linux/Mac laptop:

- Install Terraform, see https://learn.hashicorp.com/terraform/getting-started/install.html for instructions. Note: This repo requires Terraform 0.13 or newer

Example:
  
```
curl https://releases.hashicorp.com/terraform/0.14.4/terraform_0.14.4_linux_amd64.zip -o /tmp/terraform_0.14.4_linux_amd64.zip
cd /tmp/; unzip terraform_0.14.4_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm /tmp/terraform_0.14.4_linux_amd64.zip
terraform -v
```

On a Mac laptop/workstation you will need to install a few packages via brew.

`brew install jq watch gsed`

On a Linux laptop/workstation

`apt install jq` 

#### Install oc tools
```
$ export OCP_VERSION=4.7.7
$ curl -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-install-linux-${OCP_VERSION}.tar.gz
$ curl -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-client-linux-${OCP_VERSION}.tar.gz
$ tar xzvf openshift-install-linux-${OCP_VERSION}.tar.gz
$ tar xzvf openshift-client-linux-${OCP_VERSION}.tar.gz
$ sudo cp openshift-install /usr/local/bin
$ sudo cp oc /usr/local/bin
```
Note: Install oc tools (openshift-install oc kubectl)  with helper script: ./install-oc-tools.sh --latest 4.7


#### Install govc (vSphere CLI tool)
```
$ curl -L https://github.com/vmware/govmomi/releases/download/v0.20.0/govc_linux_amd64.gz > govc_0.20.0_linux_amd64.gz
$ gunzip govc_0.20.0_linux_amd64.gz
$ sudo mv govc_0.20.0_linux_amd64 /usr/local/bin/govc
$ sudo chmod +x /usr/local/bin/govc
```

### Deployment procedure

#### 1. Create needed folder and resouce pool for OCP.
```
$ export GOVC_URL='192.168.1.98'
$ export GOVC_USERNAME='administrator@vmware.local'
$ export GOVC_PASSWORD='XXXXXX'
$ export GOVC_NETWORK='VM Network'
$ export GOVC_DATASTORE='datastore1'
$ export GOVC_INSECURE=1 # If the host above uses a self-signed cert

$ govc folder.create /datacenter1/vm/ocp47
$ govc find / -type f|grep ocp47
/datacenter1/vm/ocp47

$ govc pool.create "/datacenter1/host/192.168.1.99/Resources/ocp47"
$ govc find / -type p
/datacenter1/host/192.168.1.99/Resources
/datacenter1/host/192.168.1.99/Resources/k8s-cluster1
/datacenter1/host/192.168.1.99/Resources/ocp47
```
#### 2.Configure DNS. 

Note: We use CoreDNS for this repo, so this is optional.

#### 3. Import OVA manualy to VSPHERE and convert to template 

Note:Import OVA automatically via govc CLI. Here's how to use to import OVAs directly from Red Hat to your VMware environment as a one-liner, make sure to adjust the version number, folder, datastore, name and url as required.

`$ govc import.ova --folder=templates --ds=datastore1 --name=rhcos-4.7.7 https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.7/4.7.7/rhcos-vmware.x86_64.ova`

#### 4.Create install-config.yaml 

Note: Ensure cluster_slug (clusterid) matches metadata: name. 
```
Get pull-secret.txt and generate ssh key-pairs

$ ssh-keygen 
Generating public/private rsa key pair.
Enter file in which to save the key (/home/davar/.ssh/id_rsa): /home/davar/.ssh/ocp4

Edit install-config.yaml and add pullSecret and sshKey (public)
```

#### 5.Customize clusters/lab/terraform.tfvars & clusters/lab/variables.tf & clusters/lab/main.tf with any relevant configuration.

#### 6.Run `make tfinit` to initialise Terraform modules

#### 7.Run `make lab` to create the VMs and generate/install ignition configs


<img src="pictures/ocp47-cluster.png?raw=true" width="900">


#### 8.Monitor install progress with `make wait-for-bootstrap`

#### 9.Check and approve pending CSRs with `make get-csr` and `make approve-csr`

#### 10.Run make bootstrap-complete to destroy the bootstrap VM

#### 11.Run `make wait-for-install` and wait for the cluster install to complete

#### 12.Check Lab
```
ssh -o IdentitiesOnly=yes -i ~/.ssh/ocp4 core@192.168.1.200
ssh -o IdentitiesOnly=yes -i ~/.ssh/ocp4 core@192.168.1.201
ssh -o IdentitiesOnly=yes -i ~/.ssh/ocp4 core@192.168.1.202
ssh -o IdentitiesOnly=yes -i ~/.ssh/ocp4 core@192.168.1.203
ssh -o IdentitiesOnly=yes -i ~/.ssh/ocp4 core@192.168.1.204

$ grep ocp47 /etc/hosts
192.168.1.203 api.ocp47.openshift.lab.int
$ nc -z -v api.ocp47.openshift.lab.int 6443
$ oc --kubeconfig openshift/auth/kubeconfig get nodes
$ oc --kubeconfig openshift/auth/kubeconfig get co
$ oc --kubeconfig openshift/auth/kubeconfig get csr

$ ssh -o IdentitiesOnly=yes -i ~/.ssh/ocp4 core@192.168.1.203 
Red Hat Enterprise Linux CoreOS 47.83.202104090345-0
  Part of OpenShift 4.7, RHCOS is a Kubernetes native operating system
  managed by the Machine Config Operator (`clusteroperator/machine-config`).

WARNING: Direct SSH access to machines is not recommended; instead,
make configuration changes via `machineconfig` objects:
  https://docs.openshift.com/container-platform/4.7/architecture/architecture-rhcos.html

---
Last login: Fri Sep 24 08:44:01 2021 from 192.168.1.100
[core@ocp47-master1 ~]$ sudo su -
Last login: Fri Sep 24 08:44:12 UTC 2021 on pts/0
[root@ocp47-master1 ~]# crictl images
[root@ocp47-master1 ~]# crictl ps -a|grep -i running


```
#### 13.Clean Lab
```
$ make nukelab
$ govc folder.destroy /datacenter1/vm/ocp47
$ govc pool.destroy "/datacenter1/host/192.168.1.99/Resources/ocp47"
```
