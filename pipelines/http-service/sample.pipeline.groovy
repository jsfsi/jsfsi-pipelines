#!groovy​

pipeline {
    agent {
        label 'jenkins-slave'
    }
    environment {
        APP_NAME = 'example'
        SCRIPTS_FOLDER = "pipeline/jsfsi-pipelines/pipelines/scripts"
        ENVIRONMENTS_FOLDER = "pipeline/environments"        
        VERSION = "0.0.${BUILD_NUMBER}"
        PROJECT_ID = "google cloud project id"
        CONTAINER_REGISTRY = "gcr.io/${PROJECT_ID}"        
        CLUSTER_NAME = "gke cluster name"
        CLUSTER_ZONE = "europe-west1-b"
    }
    stages {
        stage('Setup') {
            steps {
                withCredentials([
                    file(credentialsId: "${APP_NAME}-service-account-key", variable: "FILE")
                ]) {
                    sh script: "git clean -xfd", label: "Cleanup"
                    sh script: "gcloud auth activate-service-account --key-file=\"${FILE}\"", label: "GCloud login"                    
                }
            }
        }
        stage('Build') {
            steps {
                sh script: "${SCRIPTS_FOLDER}/docker/01-build.sh ${APP_NAME} ${VERSION} ${CONTAINER_REGISTRY} packages/${APP_NAME}/Dockerfile $(pwd)", label: "Build ${APP_NAME}"
            }
        }
        stage('Publish artifacts') {
            steps {
                withCredentials([
                    file(credentialsId: 'uefa-service-account-key', variable: 'FILE')
                ]) {
                    sh script: "${SCRIPTS_FOLDER}/gcloud/docker/01-publish.sh ${APP_NAME} ${VERSION} ${CONTAINER_REGISTRY} ${PROJECT_ID}", label: "Publish ${APP_NAME}"
                }
            }
        }
        stage('Deploy QA') {
            steps {
                sh script: ". ${ENVIRONMENTS_FOLDER}/deploy.qa.env && gcloud container clusters get-credentials --project=\"${PROJECT_ID}\" --zone=\"${CLUSTER_ZONE}\" \"${CLUSTER_NAME}\"", label: "Get GKE Credentials"
                sh script: "${SCRIPTS_FOLDER}/gcloud/kubernetes/01-deploy.sh ${ENVIRONMENTS_FOLDER}/application.qa.env ${ENVIRONMENTS_FOLDER}/deploy.qa.env" , label: "Deploy ${APP_NAME}"
            }
        }
        stage('Deploy Production') {
            steps {
                sh script: ". ${ENVIRONMENTS_FOLDER}/deploy.production.env && gcloud container clusters get-credentials --project=\"${PROJECT_ID}\" --zone=\"${CLUSTER_ZONE}\" \"${CLUSTER_NAME}\"", label: "Get GKE Credentials"
                sh script: "${SCRIPTS_FOLDER}/kubernetes/01-deploy.sh ${ENVIRONMENTS_FOLDER}/application.production.env ${ENVIRONMENTS_FOLDER}/deploy.production.env", label: "Deploy ${APP_NAME}"
            }
        }
    }
}
