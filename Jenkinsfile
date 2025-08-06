```groovy
pipeline {
    agent {
        docker { image 'node:16' } // Use node:16 as the base agent for consistency
    }

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '036616702180.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'dev/test-image'
        BASE_IMAGE_TAG = 'build'
        AWS_CREDENTIALS_ID = '5a88723e-cde2-4bb6-b062-b6d63467e683'
        KUBECONFIG_CREDENTIALS_ID = 'k8s-kubeconfig' // Jenkins secret file for kubeconfig
        K8S_NAMESPACE = 'default' // Kubernetes namespace
        K8S_DEPLOYMENT = 'your-deployment-name' // Replace with your deployment name
        K8S_CONTAINER = 'your-container-name' // Replace with your container name
        UNIQUE_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${BASE_IMAGE_TAG}-${currentBuild.number}-${env.GIT_COMMIT.take(7)}"
        LATEST_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Checked out code from ${env.GIT_URL}"
            }
        }

        stage('Build Application') {
            steps {
                sh 'npm install'
                // Uncomment if you need to build the app
                // sh 'npm run build'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${env.UNIQUE_IMAGE_NAME}"
                    docker.build("${env.UNIQUE_IMAGE_NAME}", ".")
                    sh "docker tag ${env.UNIQUE_IMAGE_NAME} ${env.LATEST_IMAGE_NAME}"
                    sh "docker images ${ECR_REGISTRY}/${ECR_REPOSITORY} --format '{{.Repository}}:{{.Tag}}'"
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    echo "Pushing images to ECR: ${env.UNIQUE_IMAGE_NAME} and ${env.LATEST_IMAGE_NAME}"
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
                docker { image 'bitnami/kubectl:1.28' } // Use a specific kubectl version
            }
            steps {
                script {
                    withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG_FILE')]) {
                        // Check if deployment.yml exists
                        sh '[ -f deployment.yml ] || echo "ERROR: deployment.yml not found in workspace"'
                        
                        // Update image in deployment.yml
                        echo "Updating deployment.yml with image: ${env.UNIQUE_IMAGE_NAME}"
                        sh """
                            sed -i "s|IMAGE_TO_DEPLOY|${env.UNIQUE_IMAGE_NAME}|g" deployment.yml
                            cat deployment.yml
                        """
                        
                        // Apply deployment and verify rollout
                        echo "Deploying to Kubernetes namespace: ${K8S_NAMESPACE}"
                        sh """
                            kubectl --kubeconfig=${KUBECONFIG_FILE} apply -f deployment.yml --namespace=${K8S_NAMESPACE}
                            kubectl --kubeconfig=${KUBECONFIG_FILE} rollout status deployment/${K8S_DEPLOYMENT} --namespace=${K8S_NAMESPACE} --timeout=300s
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
            echo "CI/CD pipeline succeeded! Deployed ${env.UNIQUE_IMAGE_NAME} to Kubernetes"
        }
        failure {
            echo "CI/CD pipeline failed!"
        }
    }
}
```
