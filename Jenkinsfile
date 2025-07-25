pipeline {
    agent any
    environment {
        AWS_REGION = "ap-south-1" // e.g., us-east-1
        ECR_REGISTRY = "036616702180.dkr.ecr.ap-south-1.amazonaws.com"
        IMAGE_NAME = "my-app" // e.g., my-app
        CLUSTER_NAME = "traya-dev-eks-cluster" // e.g., my-eks-cluster
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${ECR_REGISTRY}/${IMAGE_NAME}:latest")
                }
            }
        }
        stage('Push to ECR') {
            steps {
                script {
                    withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                        sh "docker push ${ECR_REGISTRY}/${IMAGE_NAME}:latest"
                    }
                }
            }
        }
        stage('Deploy to EKS') {
            steps {
                script {
                    withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                        sh "aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}"
                        sh "kubectl apply -f deployment.yml"
                    }
                }
            }
        }
        stage('Get Service URL') {
            steps {
                script {
                    def serviceUrl = ""
                    timeout(time: 5, unit: 'MINUTES') {
                        while(serviceUrl == "") {
                            serviceUrl = sh(script: "kubectl get svc my-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'", returnStdout: true).trim()
                            if(serviceUrl == "") {
                                echo "Waiting for LoadBalancer IP..."
                                sleep 10
                            }
                        }
                        echo "Service URL: http://${serviceUrl}"
                    }
                }
            }
        }
    }
}
