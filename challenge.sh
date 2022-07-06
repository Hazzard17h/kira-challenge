#!/bin/bash

set -e -o pipefail
cdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

for x in ssh npm ansible jq; do [[ -x "$(command -v "$x")" ]] || { echo >&2 "$x is not found or not executable"; exit 1; }; done

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
terraform -chdir="${cdir}/terraform/" apply -auto-approve
