#!/bin/bash

set -euo pipefail

jenkins_url=$1
username=$2
token=$3
domain_name=$4
secret_file_path=$5
id=$6
description=$7

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
  -F secret=@"${secret_file_path}" \
  -F "json={
      \"\": \"4\", 
      \"credentials\": {
        \"file\": \"secret\", 
        \"id\": \"${id}\", 
        \"description\": \"${description}\", 
        \"stapler-class\": \"org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl\", 
        \"\$class\": \"org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl\"
      }
    }"

# shellcheck disable=SC2164
popd > /dev/null
