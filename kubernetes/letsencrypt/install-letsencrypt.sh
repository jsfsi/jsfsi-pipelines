#!/bin/bash

set -eo pipefail

pushd "$(dirname "${BASH_SOURCE[0]}")" || return 1

export LETSENCRYPT_EMAIL="${1}"

# Setup Helm
kubectl apply -f tiller.yaml

helm init --service-account tiller

kubectl patch deploy --namespace kube-system \
        tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

echo "Wait for tiller to be available"
sleep 1m

kubectl apply -f 00-crds.yaml --validate=false

helm repo add jetstack https://charts.jetstack.io

helm repo update

echo "Install Cert Manager"
helm install \
  --name cert-manager \
  --namespace kube-system \
  --version v0.11.0 \
  jetstack/cert-manager

sleep 1m

echo "Setup Cluster Issuer"
envsubst < cluster_issuer.yaml > cluster_issuer.tmp.yaml
kubectl apply -f cluster_issuer.tmp.yaml
rm cluster_issuer.tmp.yaml

popd || return 1
