#!/bin/bash

set -euo pipefail

app_name=$1
version=$2
project_id=$3

script_dir=$(dirname "$(pwd)/$0")

# shellcheck disable=SC2164
pushd "$script_dir" > /dev/null

container_registry="gcr.io/${project_id}"

gcloud auth configure-docker --quiet --project="${project_id}"
docker push "${container_registry}/${app_name}:$version"
docker push "${container_registry}/${app_name}:latest"

# shellcheck disable=SC2164
popd > /dev/null
