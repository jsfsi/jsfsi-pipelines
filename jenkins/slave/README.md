# JENKINS SLAVE

Jenkins provides hundreds of plugins to support building, deploying and automating any project. <https://jenkins.io/>

## Set version

```sh
latest_version=$(date '+%Y%m%d%H%M%S')
```

## Build

```sh
container_registry="gcr.io/${project_id}"
pipelines/scripts/docker/01-build.sh jenkins_slave ${latest_version} ${container_registry} $(pwd)/jenkins/slave/DockerFile $(pwd)/jenkins/slave
```

### Publish to gcloud

```sh
gcloud auth login
pipelines/scripts/gcloud/docker/01-publish.sh jenkins_slave ${latest_version} ${project_id}
```

### Deploy to kubernetes

```sh
gcloud auth login
gcloud container clusters get-credentials --project="${project_id}" --zone="${cluster_zone:-europe-west1-b}" "${cluster_name}"
JENKINS_SLAVE_SECRET="" VERSION=${latest_version} pipelines/scripts/kubernetes/01-deploy.sh ${application_environment_variables_file_path} ${deployment_environment_variables_file_path}
```
