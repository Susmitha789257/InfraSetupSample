
pipeline {
    agent any

    environment {
        AWS_REGION = "ap-northeast-3"
        ACCOUNT_ID = "860616632758"
        FRONTEND_REPO = "frontend"
        BACKEND_REPO = "backend"
        DATABASE_REPO = "database"
        CLUSTER_NAME = "ekscluster"
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
        stage('Connect to EKS') {
            steps {
                sh '''
                aws eks update-kubeconfig \
                --region $AWS_REGION \
                --name $CLUSTER_NAME
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                kubectl apply -f ./k8s/database.yaml
                kubectl apply -f ./k8s/backend.yaml
                kubectl apply -f ./k8s/frontend.yaml
                '''
            }
        }

        stage('Verify Deployment') {
                steps {
                    sh '''
                    kubectl get pods
                    kubectl get svc
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

