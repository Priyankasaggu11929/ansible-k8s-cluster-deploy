# [Solution] TKG-SRE Candidate Homework - ap-southeast-2

## Contents

- [Introduction](#Introduction)
- [Tools & Other Software](#Tools-and-Software)
- [Prerequistes](#Prerequistes)
- [Project description](#Project-description)
- [Instructions to provision the cluster](#Instructions-to-provision-the-cluster)

##  Introduction

The following document demonstrates the process and the steps followed, to configure a Kubernetes cluster, on Amazon EC2 instances.

I have used `Ansible` playbooks to automate the provisioning of AWS EC2 instances, security groups & key pairs, and further initiating & bootstrapping the kubernetes cluster on EC2 instances (as `master` & `worker` nodes) using the `kubeadm` tool.  


## Tools and Software

Before laying down steps/instructions for the provisioning the cluster, here’s a compiled list of the tools/software/services used.

#### On the Local Machine

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) (configured with the aws account credentials & set to the required region)
    - **region:** *ap-southeast-2*
    - **ami-id:** *ami-0f39d06d145e9bb63 (Ubuntu Server 18.04 LTS (HVM))*
    - **instance type:**  *t3.small*
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) - core 2.11.3
    - [amazon.aws.ec2](https://docs.ansible.com/ansible/latest/collections/amazon/aws/ec2_module.html) module
- [Python](https://www.python.org/downloads/) 3.9.5 
- [pip](https://itsfoss.com/install-pip-ubuntu/) 21.2.1
- Python modules:
    - [Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/quickstart.html)


#### On the AWS EC2 instances

- [Docker](https://docs.docker.com/engine/install/ubuntu/)
- [kubelet, kubeadm, & kubectl](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)



## Prerequistes

- Create a SSH key pair (in my case, I’ve named it `ansible`)

  (Handed over in the email thread. Please add it on the right path, `~/.ssh/ansible`)

  ```
  $ ssh-keygen -t rsa
 
  Generating public/private rsa key pair.
  Enter file in which to save the key (/root/.ssh/id_rsa): /user/.ssh/ansible
  Enter passphrase (empty for no passphrase):
  Enter same passphrase again:
  ```
  

## Project description

The project uses Ansible to automate the provisioning of Amazon EC2 machines (& other required resources), as well further process of bootstrapping the kubernetes cluster.

The project is using the following 2 ansible playbook(s) : 

- **[create-cluster.yml](##create-clusteryml-does-the-following-in-order)**: create two EC2 instances, & bootstrap them as cluster nodes using the tool `kubeadm`.
- **[delete-cluster.yml](##delete-clusteryml-does-the-following-in-order)**: decommissions the cluster, deletes the EC2 instances along with the securitygroup & key pairs.
    
---

### `create-cluster.yml` does the following in order:

- Creates an EC2 key pair and saves the private key to the `keys` directory on localhost (in the project directory).
- Determines the default VPC and its subnets, in the `ap-southeast-2` region. And then randomly selects a subnet from the list to host the EC2 instances.
- Creates a security group to be attached to the cluster.
- Creates two EC2 instances (to be `master` & `worker` nodes later) in the above selected subnet and associated with the security group (created above). 
- Updates the `inventory/ec2` hosts file with the new master & worker nodes’ host IPs.
- Add the `ansible.pub` SSH public key to the master & worker hosts.


**Next, it bootstraps the kubernetes cluster on the above ec2 instances**

##### Setup cluster dependencies  (`kube-cluster/kube-dependencies.yml`):
        
- *On both master & worker EC2 instances:*
    - Install `Docker`, the container runtime for the kubernetes cluster.
    - Install `apt-transport-https`, to allow adding external HTTPS sources to the APT source list.
    - Add the apt key of the Kubernetes APT repository for key verification
    - Add the Kubernetes APT repository to the remote server APT sources list
    - Install `Kubelet` and `Kubeadm`

- *On master EC2 instance:*
    - Install `kubectl` (as only Kubectl commands will be run from the master)


##### Initialize the cluster using `Kubeadm` on the master node (`kube-cluster/master.yml`):

- *On master EC2 instance:*
    -  Run `kubeadm init` in order to initialize the kubernetes cluster, passing an argument `--pod-network-cidr = 10.244.0.0/16` to specify the private subnet from which the pod IPs will be assigned. (Flannel uses the old subnet by default - Kubeadm is told to use the same subnet)
    - Create `/home/ubuntu/.kube`, to contain the kubernetes cluster configuration file.
    - Copy the `/etc/kubernetes/admin.conf` file generated by `kubeadm init` to `/home/ubuntu/.kube/config`
    - Install flannel (for pod network)
    
##### Add worker node to the cluster - `kube-cluster/workers.yml`

- *On master EC2 instance:*
    - From the master node, grab the `kubeadm join ...` command using `kubeadm token create --print-join-command` & set it as an ansible artifact.

- *On worker EC2 instance:*
    - Execute the above join command to attach it as a worker node in the above initiated kubernetes cluster.

- *On master EC2 instance:*
    - Copy the `kubeconfig` file from the master node to the local machine, at folder `kubeconfig/admin.conf` in the active directory.

---

### `delete-cluster.yml` does the following in order:

- Delete both the EC2 instances (master & worker nodes)
- Delete the security group that was attached to the above instances
- Delete the Key pair
- Clean the `inventory/ec2` hosts file
- Clean the locally saved EC2 private keys
- Clean the locally saved cluster kubeconfig file

---

## Instructions to provision the cluster

**[Step1]  Clone the project**

- Run the following command to clone the project:

  `git clone git@github.com:Priyankasaggu11929/k8s-deploy-playbook.git`

**[Step2] Create the cluster**

- Run the `create-cluster.yml` ansible playbook with the command:

  `make create-cluster`
  
  In case of a kubernetes cluster with multiple worker nodes, run the following command, providing an argument `worker` value:
  
  For ex: `make create-cluster worker=2`

**[Step3] Get the kube-config file**

- This is copied from the cluster's master node running in AWS EC2

  `make get_kubeconig`
  
**[Step4] Decommission the cluster & clean the project**
  
- Run the `delete-cluster.yml` ansible playbook with the command:

  `make delete_cluster`
  

***Note:*** *Clean the project using `make delete_cluster`, before re-running the `make create-cluster` command.*

