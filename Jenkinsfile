pipeline {
agent any

```
environment {
    AWS_REGION   = "ap-northeast-3"
    ACCOUNT_ID   = "076640813977"
    REPOSITORY   = "frontend"
    IMAGE_TAG    = "latest"

    ECR_URI      = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    ECS_CLUSTER  = "my-ecs-cluster"
    ECS_SERVICE  = "frontend-service"
}

stages {

    stage('Checkout Code') {
        steps {
            checkout scm
        }
    }

    stage('Login to ECR') {
        steps {
            sh '''
            echo "Logging into Amazon ECR"
            aws ecr get-login-password --region $AWS_REGION | \
            docker login --username AWS --password-stdin \
            $ECR_URI
            '''
        }
    }

    stage('Build Docker Image') {
        steps {
            sh '''
            echo "Building Docker image"
            docker build -t $REPOSITORY:$IMAGE_TAG .
            '''
        }
    }

    stage('Tag Docker Image') {
        steps {
            sh '''
            echo "Tagging Docker image"
            docker tag $REPOSITORY:$IMAGE_TAG \
            $ECR_URI/$REPOSITORY:$IMAGE_TAG
            '''
        }
    }

    stage('Push Image to ECR') {
        steps {
            sh '''
            echo "Pushing Docker image to ECR"
            docker push $ECR_URI/$REPOSITORY:$IMAGE_TAG
            '''
        }
    }

    stage('Deploy to ECS') {
        steps {
            sh '''
            echo "Deploying to ECS"

            aws ecs update-service \
            --cluster $ECS_CLUSTER \
            --service $ECS_SERVICE \
            --force-new-deployment \
            --region $AWS_REGION
            '''
        }
    }
}

post {
    success {
        echo "Deployment successful 🚀"
    }
    failure {
        echo "Deployment failed ❌"
    }
}
```

}

