pipeline {
    agent {
        label "jenkins-jx-base"
    }
    environment {
        ORG         = 'jenkinsxio'
        APP_NAME    = 'nexus'
        GIT_CREDS    = credentials('jenkins-x-git')
    }
    stages {
        stage('CI Build and Test') {
            when {
                branch 'PR-*'
            }
            environment {
                PREVIEW_VERSION = "0.0.0-SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
                PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
                HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
            }
            steps {
                container('jx-base'){
                    sh "docker build -t docker.io/$ORG/$APP_NAME:$PREVIEW_VERSION ."
                    // disable push until we deploy to a preview environment
                    // sh "docker push docker.io/$ORG/$APP_NAME:$PREVIEW_VERSION"
                }
            
                dir ('charts/nexus') {
                    container('jx-base') {
                        sh "helm init --client-only"

                        sh "make build"
                        sh "helm template ."
                    }
                }
            }
        }

        stage('Build and Release') {
            environment {
                CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
            }
            when {
                branch 'master'
            }
            steps {
                container('jx-base') {
                    // ensure we're not on a detached head
                    sh "git checkout master"
                    // until we switch to the new kubernetes / jenkins credential implementation use git credentials store
                    sh "git config --global credential.helper store"

                    sh "echo \$(jx-release-version) > version/VERSION"
                    sh "jx step tag --version \$(cat version/VERSION)"

                    sh "docker build -t docker.io/$ORG/$APP_NAME:\$(cat version/VERSION) ."
                    sh "docker push docker.io/$ORG/$APP_NAME:\$(cat version/VERSION)"
                }

                dir ('charts/nexus') {
                    container('jx-base') {
                        sh "helm init --client-only"
                        sh "make release"
                    }
                }
            }
        }
    }
}