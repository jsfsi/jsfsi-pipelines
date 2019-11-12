#!/bin/bash

set -euo pipefail

jenkins_url=$1
username=$2
token=$3
domain_name=$4
ssh_key_path=$5
id=$6
key_username=$7
passphrase=$8
description=$9

script_dir=$(dirname "$(pwd)/$0")

# shellcheck disable=SC2164
pushd "$script_dir" > /dev/null

sed 's|$|\\n|' ${ssh_key_path} > credentials.tmp

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
--data-urlencode "json={  
  \"\": \"0\",
  \"credentials\": {
    \"scope\": \"GLOBAL\",
    \"id\": \"${id}\",
    \"username\": \"${key_username}\",
    \"passphrase\": \"${passphrase}\",
    \"privateKeySource\": {
      \"stapler-class\": \"com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource\",
      \"privateKey\": \"$(tr -d '\n' < ./credentials.tmp)\",
    },
    \"description\": \"${description}\",
    \"stapler-class\": \"com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\"
  }
}"

rm credentials.tmp

# shellcheck disable=SC2164
popd > /dev/null
