#!/bin/bash

set -euo pipefail

jenkins_url=$1
username=$2
token=$3
domain_name=$4
description=$5

script_dir=$(dirname "$(pwd)/$0")

# shellcheck disable=SC2164
pushd "$script_dir" > /dev/null

curl "${jenkins_url}/credentials/store/system/createDomain" \
--user "${username}":"${token}" \
--data-urlencode "json={  
  \"name\": \"${domain_name}\",
  \"description\": \"${description}\"
}"

# shellcheck disable=SC2164
popd > /dev/null
