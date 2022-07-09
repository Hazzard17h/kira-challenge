#!/bin/bash

set -e -o pipefail
cdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

for x in ssh npm ansible terraform helm kubectl jq; do [[ -x "$(command -v "$x")" ]] || { echo >&2 "$x is not found or not executable"; exit 1; }; done

echo "### VMs Provisioning ###"
npm install
npx cdk bootstrap
npx cdk deploy --require-approval never

echo "### Configuration ###"
"${cdir}/scripts/config-ansible-from-cdk.sh"
ansible-galaxy role install geerlingguy.docker
ansible-playbook ansible/configuration.yaml

echo "### Cluster Provisioning ###"
"${cdir}/scripts/config-terraform-from-cdk.sh"
terraform -chdir="${cdir}/terraform/" init
terraform -chdir="${cdir}/terraform/" apply -target="module.cluster" -auto-approve
terraform -chdir="${cdir}/terraform/" apply -auto-approve

echo "### App Deployment ###"
export KUBECONFIG="${cdir}/terraform/.kube.config"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install prometheus -f "${cdir}/helm/values-prometheus.yaml" prometheus-community/prometheus --namespace kiratech-test
helm install grafana -f "${cdir}/helm/values-grafana.yaml" grafana/grafana --namespace kiratech-test

echo; echo "Visit: http://$(cat "${cdir}/cdk/outputs.json" | jq -r ".VMStack.masterIP"):30080"
echo "User: admin"
echo "Password: $(kubectl -n kiratech-test get secret grafana -o json | jq -r '.data["admin-password"]' | base64 -d)"; echo
