pipeline {
    agent any
    environment {
        AWS_REGION = 'ap-south-1' // Replace with your AWS region
        ECR_REGISTRY = '036616702180.dkr.ecr.ap-south-1.amazonaws.com' // Replace with your ECR registry
        IMAGE_NAME = "${ECR_REGISTRY}/test-jenk" // Replace 'myapp' with your ECR repo name
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/info-s-a-g-a-r/test.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    def imageTag = "${env.BUILD_NUMBER}" // Use Jenkins build number as tag
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                    sh "docker build -t ${IMAGE_NAME}:${imageTag} ."
                    sh "docker tag ${IMAGE_NAME}:${imageTag} ${IMAGE_NAME}:latest"
                }
            }
        }
    }
    post {
        always {
            sh 'docker logout' // Clean up Docker login
        }
        success {
            echo 'Docker image built successfully!'
        }
        failure {
            echo 'Docker image build failed.'
        }
    }
}
