#!/bin/bash

set -euo pipefail

application_environment_variables_file_path=${1}
deployment_environment_variables_file_path=${2}

script_dir=$(dirname "$(pwd)/$0")

# shellcheck disable=SC2164
pushd "$script_dir" > /dev/null

if [ -f "${application_environment_variables_file_path}" ]; then
    # shellcheck disable=SC1090
    source "${application_environment_variables_file_path}"
fi

# shellcheck disable=SC1090
source "${deployment_environment_variables_file_path}"

if ! kubectl get namespaces | grep "${NAMESPACE}"
then
    kubectl create namespace "${NAMESPACE}"
fi

temp_folder="./kubernetes-temp"
mkdir -p "${temp_folder}/deploy"
# shellcheck disable=SC2086
cp ${K8S_TEMPLATES_FOLDER}/*.yaml "${temp_folder}"

check_deployment=0
check_daemonset=0

for filename in "${temp_folder}"/*.yaml; do
    base_filename=$(basename "$filename")

    if [[ "${base_filename}" == *"configmap.yaml" ]]; then
        # shellcheck disable=SC2086
        # shellcheck disable=SC2016
        envsubst '$NAMESPACE $SERVER_PORT $DOMAIN' < "$filename" > "${temp_folder}/deploy/${base_filename}"
    else
        # shellcheck disable=SC2086
        envsubst < "$filename" > "${temp_folder}/deploy/${base_filename}"
    fi

    [[ $check_deployment -ne 1 ]] &&
    [[ "${base_filename}" == *"deployment.yaml" ]] && check_deployment=1

    [[ $check_daemonset -ne 1 ]] &&
    [[ "${base_filename}" == *"daemonset.yaml" ]] && check_daemonset=1

    kubectl apply -f "${temp_folder}/deploy/${base_filename}"
done

if [[ $check_deployment -eq 1 ]]; then
    kubectl rollout status deployment "${APP_NAME}" --namespace "${NAMESPACE}"
fi

if [[ $check_daemonset -eq 1 ]]; then
    kubectl rollout status daemonset "${APP_NAME}" --namespace "${NAMESPACE}"
fi

rm -rf "${temp_folder}"

# shellcheck disable=SC2164
popd > /dev/null
