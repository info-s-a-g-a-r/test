pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1' // Replace with your AWS region
        ECR_REGISTRY = '123456789012.dkr.ecr.us-east-1.amazonaws.com' // Replace with your ECR registry
        ECR_REPOSITORY = 'my-app-repo' // Replace with your ECR repo name
        IMAGE_TAG = "${env.BUILD_NUMBER}" // Use Jenkins build number as image tag
        AWS_CREDENTIALS_ID = 'aws-ecr-credentials' // Credential ID from Jenkins
        KUBE_CREDENTIALS_ID = 'kubeconfig' // Optional: Kubernetes credentials ID
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/username/repo.git' // Replace with your repo
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}")
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
        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig([credentialsId: KUBE_CREDENTIALS_ID]) {
                    sh """
                        sed -i 's|IMAGE_TAG|${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}|g' deployment.yml
                        kubectl apply -f deployment.yml
                    """
                }
            }
        }
    }
    post {
        always {
            cleanWs() // Clean workspace after build
        }
    }
}
