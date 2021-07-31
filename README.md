# [solution] Deploy kubernetes cluster on AWS EC2 instances

## Contents

- [Introduction](#Introduction)
- [Tools & Other Software](#Tools-and-Software)
- [Prerequistes](#Prerequistes)
- [Project description](#Project-description)
- [Instructions to provision the cluster](#Instructions-to-provision-the-cluster)

##  Introduction

The following document demonstrates the process and the steps followed, to configure a Kubernetes cluster, on AWS EC2 instances.

I have used `Ansible` playbooks to automate the provisioning of AWS EC2 instances, the security-group & key pairs, and the further process of initiating & bootstrapping the kubernetes cluster on EC2 instances (as `master` & `worker` nodes) using the `kubeadm` tool.  


## Tools and Software

Before laying down steps/instructions for provisioning the cluster, here’s a compiled list of the tools/software/services I used.

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

  *(Handed over in the email thread. Please add it on the right path i.e, `~/.ssh/ansible`)*

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

- **[create-cluster.yml](##create-clusteryml-does-the-following-in-order)**: create AWS EC2 instances, & bootstrap them as cluster nodes using the tool `kubeadm`.
- **[delete-cluster.yml](##delete-clusteryml-does-the-following-in-order)**: decommission the kubernetes cluster by deleting the EC2 instances along with the security-group & key pairs. Also, clean the locally saved private keys, cluster kubeconfig file and the ansible hosts inventory.
    
---

### `create-cluster.yml` does the following in order:

![create-cluster-yaml](https://user-images.githubusercontent.com/30499743/127725521-fd178450-e688-4ad0-80cb-b208eac35583.jpg)


- In the specified AWS account (and specified region), it creates an EC2 key pair, further saving the private key to the `keys` directory on localhost (in the project directory).
- Determines the default VPC and its subnets, in the `ap-southeast-2` region. Then randomly select a subnet from the list to host the EC2 instances.
- Create a security group to be attached to the EC2 instances.
- In the above selected subnet, it creates two EC2 instances (to be `master` & `worker` nodes later) associated with the security group (created above).
- Updates the `inventory/ec2` hosts file with the new master & worker node's host IPs.
- Add the `ansible.pub` SSH public key to the remote master & worker hosts.


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
    -  Run `kubeadm init` in order to initialize the kubernetes cluster, passing an argument `--pod-network-cidr = 10.244.0.0/16` to specify the private subnet from which the pod IPs will be assigned.
    - Create `/home/ubuntu/.kube`, to contain the kubernetes cluster configuration file.
    - Copy the `/etc/kubernetes/admin.conf` file generated by `kubeadm init` to `/home/ubuntu/.kube/config`
    - Install flannel (for pod network)
    
##### Add worker node to the cluster - `kube-cluster/workers.yml`

- *On master EC2 instance:*
    - From the master node, grab the `kubeadm join ...` command using `kubeadm token create --print-join-command` & set it as an ansible artifact.

- *On worker EC2 instance:*
    - Execute the above `kubeadm join` command to attach it as a worker node in the kubernetes clustee initiated during the previous steps.

- *On master EC2 instance:*
    - Copy the `kubeconfig` file from the master node to the local machine, at folder `kubeconfig/admin.conf` in the active directory.

---

### `delete-cluster.yml` does the following in order:

![delete-cluster-yml](https://user-images.githubusercontent.com/30499743/127725544-4061d864-e3e0-4eab-b107-b4ccf1f5cc1e.jpg)

- Delete the EC2 instances (master & worker nodes of the kubernets cluster)
- Delete the security group that was attached to the above instances
- Delete the Key pair
- Clean the `inventory/ec2` hosts file
- Clean the locally saved EC2 private keys
- Clean the locally saved cluster kubeconfig file

---

## Instructions to provision the cluster

**[Step 1]  Configure the AWS CLI**

- Run the following command to login into the provided aws account using aws-cli, providing the respective `AWS Access Key ID` , `AWS Secret Access Key`, & required `region` name.

  ```
  aws configure
  ```
  
**[Step 2]  Clone the project**

- Run the following command to clone the project on your local machine:

  ```
  git clone git@github.com:Priyankasaggu11929/ansible-k8s-cluster-deploy.git
  ```

**[Step 3]** Organise the SSH keys in right places.

- Copy the provided SSH key (`ansible.pub`) in the required path

  ```
  cp <path-to-downloads>/ansible.pub ~/.ssh/
  ```

- Copy the provided EC2 private key (`kubernetes-key.pem`) in the required path

  ```
  cp <path-to-downloads>/kubernetes-key.pem keys/
  ```

**[Step 4] Create the cluster**

- It will run the `create-cluster.yml` ansible playbook

  ```
  make create-cluster
  ```
  
  In case, you want to create a kubernetes cluster with **multiple worker nodes**, run the following command, providing the worker node count using the argument `worker=n`:
  
  For ex: 
  
  ```
  make create-cluster worker=2
  ```

**[Step 5] Get the kube-config file**

- The kubeconfig file is copied from the kubernetes cluster's master node running in AWS EC2 instance (during the Step 4)

  ```
  make get_kubeconfig
  ```
  
**[Step 6] Decommission the cluster & clean the project**
  
- It will run `delete-cluster.yml` ansible playbook

  ```
  make delete_cluster
  ```

###### Note: Clean the project using `make delete_cluster`, before re-running the `make create-cluster` command.

