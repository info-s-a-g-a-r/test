pipeline {
    agent any
    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '036616702180.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'dev/test-image' // Updated to match your error log
        IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
        AWS_CREDENTIALS_ID = '5a88723e-cde2-4bb6-b062-b6d63467e683'
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
            // Get the current build number
            def buildNumber = currentBuild.number
            // Define a new image tag that includes the build number
            def newImageTag = "${IMAGE_TAG}-${buildNumber}"
            
            // Build the Docker image with the new tag
            def dockerImage = docker.build("${ECR_REGISTRY}/${ECR_REPOSITORY}:${newImageTag}", ".")
            
            // Set the new full image name in an environment variable for later stages
            env.FULL_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${newImageTag}"
        }
    }
}
stage('Push to ECR') {
    steps {
        script {
            withAWS(credentials: AWS_CREDENTIALS_ID, region: AWS_REGION) {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    docker push ${FULL_IMAGE_NAME}
                """
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
