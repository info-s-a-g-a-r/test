pipeline {
    agent any
    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '036616702180.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'dev/test-image' // Updated to match your error log
        IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
        AWS_CREDENTIALS_ID = 'AWS KEY'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Application') {
            agent {
                docker { image 'node:16' } // Run this stage in a node:16 container
            }
            steps {
                sh 'npm install'
                //sh 'npm run build || true' // Use || true if build step is optional
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    def dockerImage = docker.build("${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}", ".")
                    env.DOCKER_IMAGE = dockerImage.id
                }
            }
        }
        stage('Push to ECR') {
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS_ID, region: AWS_REGION) {
                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                            docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                        """
                    }
                }
            }
        }
    }
    post {
        always {
            sh "docker rmi ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} || true"
            cleanWs()
        }
        success {
            echo "CI succeeded! Image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
        }
        failure {
            echo "CI failed!"
        }
    }
}
