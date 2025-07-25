pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Login to ECR') {
            steps {
                script {
                    sh 'aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 036616702180.dkr.ecr.ap-south-1.amazonaws.com'
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t 036616702180.dkr.ecr.ap-south-1.amazonaws.com/dev/test-jenk:latest .'
                }
            }
        }
        stage('Push to ECR') {
            steps {
                script {
                    sh 'docker push 036616702180.dkr.ecr.ap-south-1.amazonaws.com/dev/test-jenk:latest'
                }
            }
        }
        stage('Deploy to EKS') {
            steps {
                script {
                    echo 'Deploying to EKS...'
                    // Add kubectl commands here, e.g., sh 'kubectl apply -f deployment.yaml'
                }
            }
        }
        stage('Get Service URL') {
            steps {
                script {
                    echo 'Retrieving service URL...'
                    // Add command to get service URL, e.g., sh 'kubectl get svc -o jsonpath="{.items[0].status.loadBalancer.ingress[0].hostname}"'
                }
            }
        }
    }
}
