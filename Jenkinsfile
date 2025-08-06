pipeline {
    agent any
    
    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '036616702180.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'dev/test-image'
        BASE_IMAGE_TAG = "build"
        AWS_CREDENTIALS_ID = '5a88723e-cde2-4bb6-b062-b6d63467e683'
        
        // --- New Environment Variables for CD ---
        KUBECONFIG_CREDENTIALS_ID = 'k8s-kubeconfig' // The ID of your Jenkins secret file
        K8S_NAMESPACE = 'default' // Your Kubernetes target namespace
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Application') {
            agent {
                docker { image 'node:16' }
            }
            steps {
                sh 'npm install'
                // sh 'npm run build'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    def uniqueTag = "${BASE_IMAGE_TAG}-${currentBuild.number}-${env.GIT_COMMIT.take(7)}"
                    
                    docker.build("${ECR_REGISTRY}/${ECR_REPOSITORY}:${uniqueTag}", ".")
                    sh "docker tag ${ECR_REGISTRY}/${ECR_REPOSITORY}:${uniqueTag} ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
                    
                    env.UNIQUE_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${uniqueTag}"
                    env.LATEST_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
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
        
        stage('Deploy to Kubernetes') {
            agent {
                docker {
                    image 'bitnami/kubectl:latest'
                    args '--entrypoint=/bin/sh'
                }
            }
            steps {
                withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS_ID}", variable: 'KUBECONFIG_FILE')]) {
                    sh(script: """
                        # Dynamically replace the IMAGE_TO_DEPLOY placeholder in the YAML file
                        sed -i "s|IMAGE_TO_DEPLOY|${env.UNIQUE_IMAGE_NAME}|g" deployment.yml
                        
                        echo "--- Applying Kubernetes manifest with new image tag: ${env.UNIQUE_IMAGE_NAME} ---"
                        
                        # Apply the Kubernetes manifest to the cluster
                        kubectl apply -f deployment.yml --namespace=${K8S_NAMESPACE}
                    """, env: ["KUBECONFIG=${KUBECONFIG_FILE}"])
                }
            }
        }
    }
    
    post {
        always {
            // Clean up both the unique tag and the latest tag from the local Jenkins agent
            sh "docker rmi ${env.UNIQUE_IMAGE_NAME} || true"
            sh "docker rmi ${env.LATEST_IMAGE_NAME} || true"
            cleanWs()
        }
        success {
            echo "CI/CD pipeline succeeded! Deployed image: ${env.UNIQUE_IMAGE_NAME}"
        }
        failure {
            echo "CI/CD pipeline failed!"
        }
    }
}
