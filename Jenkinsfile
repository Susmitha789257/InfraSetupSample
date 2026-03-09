pipeline {
    agent any

    environment {
        AWS_REGION = "ap-northeast-3"
        ACCOUNT_ID = "860616632758"
        FRONTEND_REPO = "frontend"
        BACKEND_REPO = "backend"
        DATABASE_REPO = "database"
    }

    stages {

        stage('Login to ECR') {
            steps {
                sh '''
                echo "Logging into ECR"
                aws ecr get-login-password --region $AWS_REGION | \
                docker login --username AWS --password-stdin \
                $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                '''
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                docker build -t $FRONTEND_REPO ./frontend
                docker build -t $BACKEND_REPO ./backend
                docker build -t $DATABASE_REPO ./database
                '''
            }
        }

        stage('Tag Images') {
            steps {
                sh '''
                docker tag $FRONTEND_REPO:latest \
                $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FRONTEND_REPO:latest

                docker tag $BACKEND_REPO:latest \
                $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$BACKEND_REPO:latest

                docker tag $DATABASE_REPO:latest \
                $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$DATABASE_REPO:latest
                '''
            }
        }

        stage('Push Images to ECR') {
            steps {
                sh '''
                docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FRONTEND_REPO:latest
                docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$BACKEND_REPO:latest
                docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$DATABASE_REPO:latest
                '''
            }
        }

        stage('Deploy Containers') {
            steps {
                sh '''
                echo "Creating Docker network"
                docker network create app-network || true

                echo "Stopping old containers"
                docker stop frontend backend mysql-db || true
                docker rm frontend backend mysql-db || true

                echo "Pulling latest images"
                docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/database:latest
                docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/backend:latest
                docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend:latest

                echo "Starting database"
                docker run -d \
                --name mysql-db \
                --network app-network \
                -p 3306:3306 \
                $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/database:latest

                sleep 15

                DB_STATUS=$(docker inspect -f '{{.State.Running}}' mysql-db)

                if [ "$DB_STATUS" != "true" ]; then
                  echo "Database failed to start"
                  exit 1
                fi

                echo "Starting backend"
                docker run -d \
                --name backend \
                --network app-network \
                -p 8000:8000 \
                $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/backend:latest

                sleep 10

                BACKEND_STATUS=$(docker inspect -f '{{.State.Running}}' backend)

                if [ "$BACKEND_STATUS" != "true" ]; then
                  echo "Backend failed to start"
                  exit 1
                fi

                echo "Starting frontend"
                docker run -d \
                --name frontend \
                --network app-network \
                -p 80:80 \
                $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend:latest

                sleep 5

                FRONTEND_STATUS=$(docker inspect -f '{{.State.Running}}' frontend)

                if [ "$FRONTEND_STATUS" != "true" ]; then
                  echo "Frontend failed to start"
                  exit 1
                fi

                echo "Deployment completed successfully"
                '''
            }
        }
    }

    post {
        success {
            echo "Build and deployment successful"
        }
        failure {
            echo "Pipeline failed"
        }
    }
}
