#!/bin/bash

set -euo pipefail

jenkins_url=$1
username=$2
token=$3
domain_name=$4
secret_username=$5
secret_password=$6
id=$7
description=$8

script_dir=$(dirname "$(pwd)/$0")

# shellcheck disable=SC2164
pushd "$script_dir" > /dev/null

key_exists=0

[[ $(curl "${jenkins_url}/credentials/store/system/domain/${domain_name}/credential/${id}" -s -o /dev/null -w "%{http_code}" --user "${username}":"${token}") == 302 ]] && key_exists=1

if [ $key_exists == 1 ];
then
    echo "Key exists"

    curl -X POST "${jenkins_url}/credentials/store/system/domain/${domain_name}/credential/${id}/doDelete" \
    --user "${username}":"${token}" \
    -d ""
fi

curl -X POST "${jenkins_url}/credentials/store/system/domain/${domain_name}/createCredentials" \
  --user "${username}":"${token}" \
  -F "json={
      \"\": \"4\", 
      \"credentials\": {
        \"username\": \"${secret_username}\", 
        \"password\": \"${secret_password}\", 
        \"id\": \"${id}\", 
        \"description\": \"${description}\", 
        \"stapler-class\": \"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\", 
        \"\$class\": \"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\"
      }
    }"

# shellcheck disable=SC2164
popd > /dev/null
