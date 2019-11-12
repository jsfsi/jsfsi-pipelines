#!/bin/bash

set -euo pipefail

deployment_environment_variables_file_path=${1}
application_environment_variables_file_path=${2}

script_dir=$(dirname "$(pwd)/$0")

# shellcheck disable=SC2164
pushd "$script_dir" > /dev/null

# shellcheck disable=SC1090
source "${deployment_environment_variables_file_path}"

if [ -f "${application_environment_variables_file_path}" ]; then
    # shellcheck disable=SC1090
    source "${application_environment_variables_file_path}"
fi

gcloud container clusters get-credentials --project="${PROJECT_ID}" --zone="${CLUSTER_ZONE}" "${CLUSTER_NAME}"

if ! kubectl get namespaces | grep "${NAMESPACE}"
then
    kubectl create namespace "${NAMESPACE}"
fi

temp_folder="./kubernetes-temp"
mkdir -p "${temp_folder}/deploy"
cp "${K8S_TEMPLATES_FOLDER}/*.yaml" "${temp_folder}"

check_deployment=0
check_daemonset=0

for filename in "${temp_folder}"/*.yaml; do
    set +eu
    kubectl describe secret -n "${NAMESPACE}" "${SSL_SECRET_NAME}"
    if [[ $? == 0 ]]; then
        certificate_secret_exists=1
    else
        certificate_secret_exists=0
    fi
    set -eu

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

    apply_file=0
    [[ "${base_filename}" != *"certificate.yaml" ]] && \
    [[ "${base_filename}" != *"ingress.nossl.yaml" ]] && \
    [[ "${base_filename}" != *"ingress.yaml" ]] && apply_file=1

    [[ $apply_file -eq 0 ]] && \
    [[ $certificate_secret_exists -eq 0 ]] && \
    [[ -v STATIC_IP ]] && \
    [[ "${base_filename}" == *"ingress.nossl.yaml" ]] && apply_file=1

    [[ $apply_file -eq 0 ]] && \
    [[ $certificate_secret_exists -eq 1 ]] && \
    [[ -v STATIC_IP ]] && \
    [[ "${base_filename}" == *"ingress.yaml" ]] && apply_file=1

    if  [[ $apply_file -eq 1 ]]; then
        kubectl apply -f "${temp_folder}/deploy/${base_filename}"
    fi

    # NOTE: [[ -v CERTIFICATE_ISSUER ]] doesnt work in MAC OS X
    apply_certificate=0
    [[ "${base_filename}" == *"certificate.yaml" ]] && \
    [[ $certificate_secret_exists -eq 0 ]] && \
    [[ -v CERTIFICATE_ISSUER ]] && apply_certificate=1

    if  [[ $apply_certificate -eq 1 ]]; then
        kubectl apply -f "${temp_folder}/deploy/${base_filename}"
        must_wait=1
        while [[ $must_wait -eq 1 ]]; do
            set +e
            kubectl describe secret -n "${NAMESPACE}" "${SSL_SECRET_NAME}"
            must_wait=$?
            set -e
            echo "$(date) Waiting for certificate to be ready"
            sleep 10s
        done
    fi
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
