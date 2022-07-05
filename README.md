# Kira-Challenge

Provisioning of a Kubernetes Cluster of 1 manager and 2 workers VMs, and deploy of an application with at least 3 services and a web UI.

The solution is tested under WSL2 Ubuntu 20.04 OS, with bash, but should work on any linux based OS.

### Prerequisites

- AWS account with write credentials for the VMs provisioning, the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with an AWS profile; export it if it's not the `default` profile: `export AWS_PROFILE=profile-name`
- OpenSSH and an SSH key pair; use `ssh-keygen` to generate a new pair, export key pair paths if they aren't the default (`~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`): `export ANSIBLE_PRIVATE_KEY_FILE=path/to/key; export SSH_PUBLIC_KEY_FILE=path/to/key.pub`
- Nodejs ≥ 14.15.0 and NPM installed

## Provisioning

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

## Teardown

Destroy the VMs with: `npx cdk destroy`
