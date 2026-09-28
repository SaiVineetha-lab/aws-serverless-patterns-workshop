pipeline {
    agent any

    triggers {
        githubPush()
        pollSCM('H/5 * * * *')
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    environment {
        PATH = "/opt/homebrew/bin:/usr/local/bin:${env.PATH}"
        VENV = "${env.WORKSPACE}/.venv"
        PIP_DISABLE_PIP_VERSION_CHECK = '1'
    }

    stages {
        stage('Setup') {
            steps {
                sh '''
                    python3 --version
                    python3 -m venv "$VENV"
                    "$VENV/bin/pip" install -q \
                        -r module-3/requirements.txt \
                        -r module-3/tests/requirements.txt \
                        cfn-lint
                '''
            }
        }

        stage('Compile') {
            steps {
                sh '''
                    "$VENV/bin/python" -m compileall -q \
                        module-1 \
                        module-3/src \
                        module-4/userprofile/src \
                        module-5/orderstatus/src
                '''
            }
        }

        stage('Lint SAM templates') {
            steps {
                sh '''
                    "$VENV/bin/cfn-lint" \
                        module-3/template.yaml \
                        module-4/userprofile/template.yaml \
                        module-5/orderstatus/template.yaml
                '''
            }
        }

        stage('Module 3 unit tests') {
            steps {
                dir('module-3') {
                    sh '"$VENV/bin/python" -m pytest tests -v --junitxml=../reports/module-3.xml'
                }
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, testResults: 'reports/*.xml'
        }
        success {
            echo "Build #${env.BUILD_NUMBER} passed for ${env.GIT_COMMIT}"
        }
        failure {
            echo "Build #${env.BUILD_NUMBER} failed for ${env.GIT_COMMIT}"
        }
    }
}
