#!/bin/bash

set -e -o pipefail
cdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

for x in npm terraform; do [[ -x "$(command -v "$x")" ]] || { echo >&2 "$x is not found or not executable"; exit 1; }; done

echo "### Clear Terraform state ###"
terraform -chdir="${cdir}/terraform/" destroy -auto-approve

echo "### Destroy the VMs ###"
npx cdk destroy --force
