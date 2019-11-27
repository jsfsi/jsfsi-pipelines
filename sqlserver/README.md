# SQL SERVER

Microsoft SQL Server is a relational database management system developed by Microsoft. As a database server, it is a software product with the primary function of storing and retrieving data as requested by other software applications.
<https://www.microsoft.com/en-us/sql-server/sql-server-2019>

## Deploy to kubernetes

More info at: <https://cloud.google.com/solutions/partners/deploying-sql-server-gke>
For persistent disk usage: <https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/preexisting-pd>

- A persistent disk must be previously created in GCP, ideally using terraform.

```sh
gcloud auth login
gcloud container clusters get-credentials --project="${project_id}" --zone="${cluster_zone:-europe-west1-b}" "${cluster_name}"
export SA_PASSWORD=""
pipelines/scripts/kubernetes/01-deploy.sh ${application_environment_variables_file_path} ${deployment_environment_variables_file_path}
```

## Setup disk snapshot

More info at: <https://cloud.google.com/compute/docs/disks/scheduled-snapshots>

- Snapshot schedule

```sh
gcloud compute resource-policies create snapshot-schedule ${APP_NAME}-${ENVIRONMENT} \
    --project ${project_id} \
    --description "Daily schedule for ${APP_NAME}-${ENVIRONMENT}" \
    --max-retention-days 5 \
    --start-time 00:00 \
    --daily-schedule \
    --region europe-west1 \
    --on-source-disk-delete keep-auto-snapshots \
    --snapshot-labels environment=${ENVIRONMENT},app_name=${APP_NAME}
```

- Snapshot

```sh
gcloud compute disks add-resource-policies ${APP_NAME}-${ENVIRONMENT} \
    --project ${project_id} \
    --resource-policies ${APP_NAME}-${ENVIRONMENT} \
    --zone europe-west1-b
```
