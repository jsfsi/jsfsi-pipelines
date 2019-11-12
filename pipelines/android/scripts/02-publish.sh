#!/bin/bash

set -euo pipefail

app_name=$1
version=$2
container_registry=$3

script_dir=$(dirname "$(pwd)/$0")

# shellcheck disable=SC2164
pushd "$script_dir" > /dev/null

docker run --name android-build "${container_registry}/${app_name}:$version" /bin/true

docker cp android-build:/app-android/app/build/outputs/apk/dev/debug/app-dev-debug.apk "${app_name}-${version}-dev.apk"

docker rm android-build

ls *.apk
# Push ${app_name}-$version.apk to some store, appcenter for example

# shellcheck disable=SC2164
popd > /dev/null
