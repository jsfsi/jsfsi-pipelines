#!/bin/bash

set -euo pipefail

app_name=$1
version=$2
container_registry=$3
dockerfile_path=${4:-Dockerfile}
context_path=${5:-../../../}

script_dir=$(dirname "$(pwd)/$0")

# shellcheck disable=SC2164
pushd "$script_dir" > /dev/null

docker build "${context_path}" -f "${dockerfile_path}" -t "${container_registry}/${app_name}:$version" --build-arg VERSION="${version}"
docker tag "${container_registry}/${app_name}:$version" "${container_registry}/${app_name}:latest"

# shellcheck disable=SC2164
popd > /dev/null
