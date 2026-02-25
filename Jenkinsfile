pipeline {
    agent any
    
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('49502e9b-34fd-47d3-b38f-7678e4e91f29')
        IMAGE_NAME = 'briancheruiyot/tooling-frontend'
        GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
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
                    BRANCH_NAME = env.BRANCH_NAME ?: 'main'
                    IMAGE_TAG = "${BRANCH_NAME}-${GIT_COMMIT_SHORT}"
                    
                    sh """
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Test Image') {
            steps {
                script {
                    sh """
                        # Create test network if not exists
                        docker network create test-network || true
                        
                        # Run MySQL test container
                        docker run -d --network test-network --name test-mysql \
                          -e MYSQL_ROOT_PASSWORD=testpass \
                          -e MYSQL_DATABASE=testdb \
                          -e MYSQL_USER=testuser \
                          -e MYSQL_PASSWORD=testpass \
                          mysql:5.7
                          
                        sleep 10
                        
                        # Run app container
                        docker run -d --network test-network --name test-app \
                          -p 8085:80 ${IMAGE_NAME}:latest
                          
                        sleep 5
                        
                        # Test endpoint
                        curl -f http://localhost:8085 || exit 1
                    """
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    sh """
                        echo ${DOCKER_HUB_CREDENTIALS_PSW} | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin
                        
                        # Push branch-specific image
                        docker push ${IMAGE_NAME}:${BRANCH_NAME}-${GIT_COMMIT_SHORT}
                        
                        # Always update latest tag
                        docker push ${IMAGE_NAME}:latest
                    """
                }
            }
        }
    }
    
    post {
        always {
            sh '''
                docker stop test-app test-mysql || true
                docker rm test-app test-mysql || true
                docker network rm test-network || true
                docker system prune -f
            '''
            cleanWs()
        }
        success {
            echo "Pipeline completed successfully! Images pushed: ${IMAGE_NAME}:${BRANCH_NAME}-${GIT_COMMIT_SHORT} and ${IMAGE_NAME}:latest"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}