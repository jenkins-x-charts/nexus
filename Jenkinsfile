pipeline {
    agent any
    environment {
        ORG         = 'jenkinsxio'
        APP_NAME    = 'nexus'
    }
    stages {
        stage('CI Build and Test') {
            when {
                environment name: 'JOB_TYPE', value: 'presubmit'
            }
            environment {
                PREVIEW_VERSION = "0.0.0-PREVIEW-$BRANCH_NAME-$BUILD_NUMBER"
                PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
                HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
            }
            steps {
                sh "docker build -t docker.io/$ORG/$APP_NAME:$PREVIEW_VERSION ."
                sh "docker push docker.io/$ORG/$APP_NAME:$PREVIEW_VERSION"

                dir ('charts/nexus') {
                    sh "helm init --client-only"

                    sh "make build"
                    sh "helm template ."
                }
            }
        }

        stage('Build and Release') {
            environment {
                CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
            }
            when {
                environment name: 'JOB_TYPE', value: 'postsubmit'
            }
            steps {
                git "https://github.com/jenkins-x/nexus"
                // until we switch to the new kubernetes / jenkins credential implementation use git credentials store
                sh "git config --global credential.helper store"
                sh "jx step git credentials"
                sh "echo \$(jx-release-version) > version/VERSION"
                sh "jx step tag --version \$(cat version/VERSION)"

                sh "docker build -t docker.io/$ORG/$APP_NAME:\$(cat version/VERSION) ."
                sh "docker push docker.io/$ORG/$APP_NAME:\$(cat version/VERSION)"
                
                dir ('charts/nexus') {
                    sh "jx step git credentials"
                    sh "helm init --client-only"
                    sh "make release"
                }
            }
        }
    }
}
