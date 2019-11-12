#!/bin/bash

set -euo pipefail

jenkins_url=$1
username=$2
token=$3
job_variables_path=$4

script_dir=$(dirname "$(pwd)/$0")

# shellcheck disable=SC2164
pushd "$script_dir" > /dev/null

# shellcheck disable=SC1090
source "${job_variables_path}"

envsubst < "${JOB_TEMPLATE_PATH}" > "./job-${JOB_NAME}.xml"

job_exists=0

if [ -n "${JOB_FOLDER}" ];
then
    base_url="${jenkins_url}/job/${JOB_FOLDER}/job"
else
    base_url="${jenkins_url}/job"
fi

[[ $(curl "${base_url}/${JOB_NAME}/api" -s -o /dev/null -w "%{http_code}" --user "${username}":"${token}") == 302 ]] && job_exists=1

if [ $job_exists == 1 ];
then
    echo "Job ${JOB_NAME} exists"

    curl -X POST "${base_url}/${JOB_NAME}/config.xml" \
    --user "${username}":"${token}" -s \
    -H "Content-Type:text/xml" \
    --data-binary @job-"${JOB_NAME}".xml 
else
    if [ -n "${JOB_FOLDER}" ];
    then
        base_url="${jenkins_url}/job/${JOB_FOLDER}"
    else
        base_url="${jenkins_url}"
    fi

    curl -X POST "${base_url}/createItem?name=${JOB_NAME}" \
    --user "${username}":"${token}" -s \
    -H "Content-Type:text/xml" \
    --data-binary @job-"${JOB_NAME}".xml 
fi

rm -f "./job-${JOB_NAME}.xml"

# shellcheck disable=SC2164
popd > /dev/null
