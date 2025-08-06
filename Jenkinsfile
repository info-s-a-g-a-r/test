```groovy
pipeline {
    agent any // Single agent to maintain Docker context

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '036616702180.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'dev/test-image'
        BASE_IMAGE_TAG = 'build'
        AWS_CREDENTIALS_ID = '5a88723e-cde2-4bb6-b062-b6d63467e683'
        UNIQUE_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${BASE_IMAGE_TAG}-${currentBuild.number}-${env.GIT_COMMIT.take(7)}"
        LATEST_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "UNIQUE_IMAGE_NAME: ${env.UNIQUE_IMAGE_NAME}"
                echo "LATEST_IMAGE_NAME: ${env.LATEST_IMAGE_NAME}"
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building image: ${env.UNIQUE_IMAGE_NAME}"
                    docker.build("${env.UNIQUE_IMAGE_NAME}", ".")
                    sh "docker images ${env.UNIQUE_IMAGE_NAME} --format '{{.Repository}}:{{.Tag}}'"
                    sh "docker tag ${env.UNIQUE_IMAGE_NAME} ${env.LATEST_IMAGE_NAME}"
                    sh "docker images ${env.LATEST_IMAGE_NAME} --format '{{.Repository}}:{{.Tag}}'"
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    echo "Pushing images: ${env.UNIQUE_IMAGE_NAME} and ${env.LATEST_IMAGE_NAME}"
                    withAWS(credentials: AWS_CREDENTIALS_ID, region: AWS_REGION) {
                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                            docker push ${env.UNIQUE_IMAGE_NAME}
                            docker push ${env.LATEST_IMAGE_NAME}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            sh "docker rmi ${env.UNIQUE_IMAGE_NAME} || true"
            sh "docker rmi ${env.LATEST_IMAGE_NAME} || true"
            cleanWs()
        }
        success {
            echo "Pipeline succeeded! Pushed image: ${env.UNIQUE_IMAGE_NAME}"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
```
