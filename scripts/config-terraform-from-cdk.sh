#!/bin/bash

set -e -o pipefail
cdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

for x in jq; do [[ -x "$(command -v "$x")" ]] || { echo >&2 "$x is not found or not executable"; exit 1; }; done

cdk_out="${cdir}/../cdk/outputs.json"
[[ -f "$cdk_out" ]] || { echo >&2 "$cdk_out not found! Have you done the provisioning?"; exit 2; }

echo "{
  \"master\": $(cat "$cdk_out" | jq '.VMStack.masterIP'),
  \"workers\": [ $(cat "$cdk_out" | jq '.VMStack.worker1IP'), $(cat "$cdk_out" | jq '.VMStack.worker2IP') ],
  \"private_key_file\": \"${ANSIBLE_PRIVATE_KEY_FILE:-"~/.ssh/id_rsa"}\"
}" > "${cdir}/../terraform/terraform.tfvars.json"
