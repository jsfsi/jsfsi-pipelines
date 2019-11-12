#!/bin/bash -x

set -euo pipefail

token=$1
username=$2
jenkins_url=https://builder.jsfsi.com/
domain_name=example

script_dir=$(dirname "$(pwd)/$0")

# shellcheck disable=SC2164
pushd "$script_dir" > /dev/null

cd ..

pipeline/scripts/credentials/create-domain.sh "${jenkins_url}" "${username}" "${token}" "${domain_name}" "Credentials domain for ${domain_name} secrets"

pipeline/scripts/credentials/add-privatekey.sh "${jenkins_url}" "${username}" "${token}" "${domain_name}" ~/.ssh/example-key "example-ssh-key" "jenkins" "" "Access Key to read example git repository"

pipeline/scripts/credentials/add-secret-file.sh "${jenkins_url}" "${username}" "${token}" "${domain_name}" "/tmp/example.service-account.key" "example-service-account-key" "JSON Key to access some service"

pipeline/scripts/credentials/add-username-password.sh "${jenkins_url}" "${username}" "${token}" "${domain_name}" "${secret_username}" "${secret_password}" "example-credentials-qa" "Example database qa Username and Password"

pipeline/scripts/jobs/create-job.sh "${jenkins_url}" "${username}" "${token}" "./sample.job.env"

# shellcheck disable=SC2164
popd > /dev/null
