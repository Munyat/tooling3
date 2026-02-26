pipeline {
    agent any
    
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('49502e9b-34fd-47d3-b38f-7678e4e91f29')
        IMAGE_NAME = 'briancheruiyot/tooling-frontend'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Prepare Variables') {
            steps {
                script {
                    BRANCH_NAME = env.BRANCH_NAME ?: 'main'
                    SAFE_BRANCH_NAME = BRANCH_NAME.replaceAll('/', '-')
                    GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    IMAGE_TAG = "${SAFE_BRANCH_NAME}-${GIT_COMMIT_SHORT}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
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
                set -e

                echo "Creating test network..."
                docker network create test-network || echo "Network exists"

                echo "Starting MySQL container..."
                docker run -d --network test-network --name test-mysql \\
                  -e MYSQL_ROOT_PASSWORD=testpass \\
                  -e MYSQL_DATABASE=testdb \\
                  -e MYSQL_USER=testuser \\
                  -e MYSQL_PASSWORD=testpass \\
                  mysql:5.7

                echo "Waiting for MySQL to be ready..."
                until docker exec test-mysql mysqladmin ping -u root -ptestpass --silent; do
                  echo "Waiting for MySQL..."
                  sleep 2
                done

                echo "Starting App container..."
                docker run -d --network test-network --name test-app -p 8080:80 \\
                  -e DB_HOST=test-mysql \\
                  -e DB_USER=testuser \\
                  -e DB_PASSWORD=testpass \\
                  -e DB_NAME=testdb \\
                  ${IMAGE_NAME}:latest

                echo "Waiting for app to be ready..."
                until curl -s http://localhost:8080 > /dev/null; do
                  echo "Waiting for app..."
                  sleep 2
                done

                echo "Testing app..."
                curl -f http://localhost:8080
            """
        }
    }
}
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    sh """
                        echo ${DOCKER_HUB_CREDENTIALS_PSW} | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin
                        
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
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
            echo "Pipeline completed successfully! Image pushed: ${IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}