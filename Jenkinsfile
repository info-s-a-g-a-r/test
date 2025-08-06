pipeline {
    agent any // Use a single agent for consistency across Docker-related stages

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '036616702180.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'dev/test-image'
        BASE_IMAGE_TAG = 'build'
        AWS_CREDENTIALS_ID = '5a88723e-cde2-4bb6-b062-b6d63467e683'
        KUBECONFIG_CREDENTIALS_ID = 'k8s-kubeconfig'
        K8S_NAMESPACE = 'default'
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
                // Uncomment if build step is required
                // sh 'npm run build'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def uniqueTag = "${BASE_IMAGE_TAG}-${currentBuild.number}-${env.GIT_COMMIT.take(7)}"
                    env.UNIQUE_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${uniqueTag}"
                    env.LATEST_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
                    
                    // Build the Docker image
                    def image = docker.build("${env.UNIQUE_IMAGE_NAME}", ".")
                    
                    // Verify the image exists
                    sh "docker images ${env.UNIQUE_IMAGE_NAME} --format '{{.Repository}}:{{.Tag}}'"
                    
                    // Tag the image as latest
                    sh "docker tag ${env.UNIQUE_IMAGE_NAME} ${env.LATEST_IMAGE_NAME}"
                    
                    // Verify the latest tag exists
                    sh "docker images ${env.LATEST_IMAGE_NAME} --format '{{.Repository}}:{{.Tag}}'"
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS_ID, region: AWS_REGION) {
                        // Configure Docker credential helper to avoid unencrypted password storage
                        sh '''
                            mkdir -p ~/.docker
                            echo '{"credsStore": "ecr-login"}' > ~/.docker/config.json
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        '''
                        
                        // Verify images before pushing
                        sh "docker images ${env.UNIQUE_IMAGE_NAME} --format '{{.Repository}}:{{.Tag}}'"
                        
                        // Push both tags
                        sh "docker push ${env.UNIQUE_IMAGE_NAME}"
                        sh "docker push ${env.LATEST_IMAGE_NAME}"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            agent {
                docker { image 'bitnami/kubectl:latest' }
            }
            steps {
                withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG_FILE')]) {
                    script {
                        sh 'test -f deployment.yml || { echo "Error: deployment.yml not found"; exit 1; }'
                        sh """
                            export KUBECONFIG=\${KUBECONFIG_FILE}
                            sed -i "s|IMAGE_TO_DEPLOY|\${UNIQUE_IMAGE_NAME}|g" deployment.yml
                            echo "Applying Kubernetes manifest with image: \${UNIQUE_IMAGE_NAME}"
                            kubectl apply -f deployment.yml --namespace=\${K8S_NAMESPACE}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                // Clean up Docker images, ignoring errors if they don't exist
                sh "docker rmi ${env.UNIQUE_IMAGE_NAME} || true"
                sh "docker rmi ${env.LATEST_IMAGE_NAME} || true"
                cleanWs()
            }
        }
        success {
            echo "CI/CD pipeline succeeded! Deployed image: ${env.UNIQUE_IMAGE_NAME}"
        }
        failure {
            echo "CI/CD pipeline failed!"
        }
    }
}
