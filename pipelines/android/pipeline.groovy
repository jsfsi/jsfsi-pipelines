#!groovy​

pipeline {
    agent {
        label 'jenkins-slave'
    }
    triggers {
        pollSCM('* * * * *')
    }
    environment {
        SCRIPTS_FOLDER = "scripts"
        APP_NAME = 'example-application'
        VERSION = "0.0.${BUILD_NUMBER}"
        CONTAINER_REGISTRY = "gcr.io/google-cloud-project-id"
        PROJECT_ID = "google-cloud-project-id"
    }
    stages {
        stage('Setup') {
            steps {
                sh "git clean -xfd", label: "Cleanup"
            }
        }
        stage('Build') {
            steps {
                sh "$SCRIPTS_FOLDER/01-build.sh $APP_NAME $VERSION $CONTAINER_REGISTRY", label: "Build app"
            }
        }
        stage('Publish to Store') {
            steps {
                sh "$SCRIPTS_FOLDER/02-publish.sh $APP_NAME $VERSION $CONTAINER_REGISTRY $FILE", label: "Publish app to store"
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'pipeline/scripts/*.apk', fingerprint: true
        }
    }
}
