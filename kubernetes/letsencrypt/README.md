# Letsencrypt

Let’s Encrypt is a free, automated, and open Certificate Authority. <https://letsencrypt.org/>

## Setup lets encrypt in kubernetes cluster

### GKE

- Login into GKE cluster

```sh
gcloud auth activate-service-account --key-file="$key_file"
gcloud container clusters get-credentials --project="${project_id}" --zone="${cluster_zone:-europe-west1-b}" "${cluster_name}
```

### Install lets encrypt in any Kubernetes cluster

```sh
./install-letsencrypt.sh ${support_email}
```
