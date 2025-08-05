pipeline {
    agent any
    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '036616702180.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'dev/test-image'
        // Define the base tag, the full tag will be created later
        BASE_IMAGE_TAG = "build"
        AWS_CREDENTIALS_ID = '5a88723e-cde2-4bb6-b062-b6d63467e683'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Application') {
            // It's good practice to declare agent at the stage level if it's different from the global agent
            agent {
                docker { image 'node:16' }
            }
            steps {
                sh 'npm install'
                // The build step is usually required, uncomment if your app needs a build step
                // sh 'npm run build'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    // Create the unique, long-lived tag for this specific build
                    def uniqueTag = "${BASE_IMAGE_TAG}-${currentBuild.number}-${env.GIT_COMMIT.take(7)}"
                    
                    // Build the Docker image with the unique tag
                    docker.build("${ECR_REGISTRY}/${ECR_REPOSITORY}:${uniqueTag}", ".")

                    // Also tag the image with 'latest'
                    sh "docker tag ${ECR_REGISTRY}/${ECR_REPOSITORY}:${uniqueTag} ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
                    
                    // Store both full image names in environment variables
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
                            # Push both the unique tag and the 'latest' tag
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
            // Clean up both the unique tag and the latest tag from the local Jenkins agent
            sh "docker rmi ${env.UNIQUE_IMAGE_NAME} || true"
            sh "docker rmi ${env.LATEST_IMAGE_NAME} || true"
            cleanWs()
        }
        success {
            echo "CI succeeded! Latest image: ${env.LATEST_IMAGE_NAME}"
            echo "Unique image: ${env.UNIQUE_IMAGE_NAME}"
        }
        failure {
            echo "CI failed!"
        }
    }
}
