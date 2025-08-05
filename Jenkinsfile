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
                    // Create the full image tag by combining base tag, build number, and a short git commit hash
                    // The 'currentBuild.number' is a built-in Jenkins variable
                    def newImageTag = "${BASE_IMAGE_TAG}-${currentBuild.number}-${env.GIT_COMMIT.take(7)}"
                    
                    // Build the Docker image with the new, unique tag
                    def dockerImage = docker.build("${ECR_REGISTRY}/${ECR_REPOSITORY}:${newImageTag}", ".")
                    
                    // Store the full image name in an environment variable for the next stage
                    env.FULL_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${newImageTag}"
                }
            }
        }
        stage('Push to ECR') {
            steps {
                script {
                    // Correctly use the withAWS step
                    withAWS(credentials: AWS_CREDENTIALS_ID, region: AWS_REGION) {
                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                            docker push ${env.FULL_IMAGE_NAME}
                        """
                    }
                }
            }
        }
    }
    post {
        always {
            // Use env.FULL_IMAGE_NAME to remove the exact image that was built and pushed
            // The || true is a good practice to prevent the pipeline from failing if the image doesn't exist
            sh "docker rmi ${env.FULL_IMAGE_NAME} || true"
            cleanWs()
        }
        success {
            echo "CI succeeded! Image: ${env.FULL_IMAGE_NAME}"
        }
        failure {
            echo "CI failed!"
        }
    }
}
