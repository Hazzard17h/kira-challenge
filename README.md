# Kira-Challenge

Provisioning of a Kubernetes Cluster of 1 manager and 2 workers VMs, and deploy of an application with at least 3 services and a web UI.

The solution is tested under WSL2 Ubuntu 20.04 OS, with bash, but should work on any linux based OS.

## Prerequisites

- AWS account with write credentials for the VMs provisioning, the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with an AWS profile; export it if it's not the `default` profile: `export AWS_PROFILE=profile-name`
- OpenSSH and an SSH key pair; use `ssh-keygen` to generate a new pair, export key pair paths if they aren't the default (`~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`): `export ANSIBLE_PRIVATE_KEY_FILE=path/to/key; export SSH_PUBLIC_KEY_FILE=path/to/key.pub`
- [Nodejs](https://nodejs.org/en/download/package-manager/) ≥ 14.15.0 and NPM installed
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html) ≥ 2.4
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started) ≥ 0.12
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) 1.23
- [helm](https://helm.sh/docs/intro/install/) ≥ 3
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

#### Considerations

The choice of the [AWS CDK](https://github.com/aws/aws-cdk) as the provisioning tool is based on the fact that I know it very well, it is open source and a great tool to reproduce an infrastructure architecture in any AWS account and region.

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

#### Considerations

I have reused [geerlingguy.docker](https://github.com/geerlingguy/ansible-role-docker) Ansible Galaxy role being that it is open source and community trusted, from one of the main contributors to Ansible Galaxy roles.

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
- First apply only the cluster module resources: `terraform -chdir=terraform/ apply -target="module.cluster"`; this is because [cannot currently chain together a provider's config with the output of a resource](https://github.com/hashicorp/terraform/issues/4149)
- Than apply all to also create K8S namespace and run security benchmark: `terraform -chdir=terraform/ apply`

#### Considerations

The K8S namespace creation is done with the official [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs).  
I have selected [kube-bench](https://github.com/aquasecurity/kube-bench) security benchmark being that it is an open source [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes).

### Application Deployment

The application deployed through Helm is the Prometheus/Grafana stack (without persistent storage) with a basic dashboard to monitor the worker nodes.

Before deploying the application, export the kube-config file path: `export KUBECONFIG="${PWD}/terraform/.kube.config"`

Deploy the application:
- Add Helm repositories:
  ```bash
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo add grafana https://grafana.github.io/helm-charts
  helm repo update
  ```
- Install Helm charts:
  ```bash
  helm install prometheus -f "helm/values-prometheus.yaml" prometheus-community/prometheus --namespace kiratech-test
  helm install grafana -f "helm/values-grafana.yaml" grafana/grafana --namespace kiratech-test
  ```

Access Grafana:
- Url: `http://{IP-of-a-node}:30080` (read the IP of the nodes in `cdk/outputs.json`)
- User: `admin`
- Password is the output of: `kubectl -n kiratech-test get secret grafana -o json | jq -r '.data["admin-password"]' | base64 -d; echo`
- Access the dashboard to monitor the worker nodes: Dashboards -> Browse -> General -> Node Exporter Full

#### Considerations

The application is deployed using two community open source Helm charts: [Prometheus](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus) and [Grafana](https://github.com/grafana/helm-charts/tree/main/charts/grafana).  
Both Prometheus and Grafana are deployed as K8S deployements with "RollingUpdate" strategy and with probes healt checks, so they should not have downtime in case of updates.

## Teardown

Manually:
- Clear Terraform state: `terraform -chdir=terraform/ destroy`
- Destroy the VMs with: `npx cdk destroy`

Or do it automatically with: `./teardown.sh`

## Code Linting

The CI pipeline to lint code is done with GitHub Actions through the use of well known open source projects:
- Terraform: [TFLint](https://github.com/terraform-linters/tflint)
- Ansible: [ansible-lint](https://github.com/ansible/ansible-lint)
- Helm (Yaml): [yamllint](https://github.com/adrienverge/yamllint)
- CDK (TypeScript): [eslint](https://github.com/eslint/eslint) ([typescript-eslint](https://github.com/typescript-eslint/typescript-eslint))
