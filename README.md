# Kira-Challenge

Provisioning of a Kubernetes Cluster of 1 manager and 2 workers VMs, and deploy of an application with at least 3 services and a web UI.

The solution is tested under WSL2 Ubuntu 20.04 OS, with bash, but should work on any linux based OS.

## Prerequisites

- AWS account with write credentials for the VMs provisioning, the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with an AWS profile; export it if it's not the `default` profile: `export AWS_PROFILE=profile-name`
- OpenSSH and an SSH key pair; use `ssh-keygen` to generate a new pair, export key pair paths if they aren't the default (`~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`): `export ANSIBLE_PRIVATE_KEY_FILE=path/to/key; export SSH_PUBLIC_KEY_FILE=path/to/key.pub`
- Nodejs ≥ 14.15.0 and NPM installed
- Ansible ≥ 2.4
- Terraform ≥ 0.12
- `jq` utility to run the scripts

## Quick start

Run all the steps of the challenge, except the teardown, with: `./challenge.sh`.

### VMs Provisioning

The provisioning of the VMs is done with the AWS CDK, in the AWS cloud.

Environment variables configuration:
- `CDK_MASTER_INSTANCE`: EC2 instance type for master node, default `t3.small`
- `CDK_WORKERS_INSTANCE`: EC2 instance type for worker nodes, default `t3.small`

Provisioning:
- Install the dependencies: `npm install`
- Bootstrap the CDK, it will use account and region configured in the AWS profile to deploy the VMs: `npx cdk bootstrap`
- See which resources will be created: `npx cdk diff`
- Deploy the resources: `npx cdk deploy`

Outputs, in `cdk/outputs.json`:
- `VMStack.MasterIP`: IP of the master node
- `VMStack.Worker{1,2}IP`: IPs of the worker nodes

### Configuration

The configuration of the VMs is done with Ansible.

Before run Ansible playbook the hosts IPs must be configured from the VMs provisioning outputs `cdk/outputs.json`
- Create `ansible/inventory/host_vars/{master,worker{1,2}}/host.yaml` files with the content:
  ```yaml
  ---

  ansible_host: {IP-of-the-host}

  ```
- Or run `./scripts/config-ansible-from-cdk.sh` to do it automatically

Run Ansible:
- Install Galaxy dependencies: `ansible-galaxy role install geerlingguy.docker`
- Configure hosts: `ansible-playbook ansible/configuration.yaml`

### Cluster Provisioning

The Kubernetes Cluster provisioning is done with Terraform.

Before apply Terraform resources the hosts IPs and SSH private key (if not the default) must be configured as variables from the VMs provisioning outputs `cdk/outputs.json`:
- Create `terraform/terraform.tfvars.json` file with the content:
  ```json
  {
    "master": "{IP-of-master-node}",
    "workers": [ "{IP-of-worker1-node}", "{IP-of-worker2-node}" ],
    "private_key_file": "path/to/key"
  }
  ```
- Or run `./scripts/config-terraform-from-cdk.sh` to do it automatically

Run Terraform:
- Init workspace: `terraform -chdir=terraform/ init`
- See which resources will be created: `terraform -chdir=terraform/ plan`
- Apply the resources: `terraform -chdir=terraform/ apply`

## Teardown

- Clear Terraform state: `terraform -chdir=terraform/ destroy`
- Destroy the VMs with: `npx cdk destroy`
