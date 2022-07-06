#!/bin/bash

set -e -o pipefail
cdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

for x in jq; do [[ -x "$(command -v "$x")" ]] || { echo >&2 "$x is not found or not executable"; exit 1; }; done

cdk_out="${cdir}/../cdk/outputs.json"
[[ -f "$cdk_out" ]] || { echo >&2 "$cdk_out not found! Have you done the provisioning?"; exit 2; }

cdk_json="$(cat "$cdk_out" | jq '.VMStack')"

for host in master worker{1,2}; do
  echo -e "---\n\nansible_host: $(echo "$cdk_json" | jq -r ".${host}IP")" > "${cdir}/../ansible/inventory/host_vars/${host}/host.yaml"
done
