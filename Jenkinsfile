pipeline {
agent any

environment {
    AWS_REGION  = "ap-northeast-3"
    ACCOUNT_ID  = "076640813977"
    REPOSITORY  = "frontend"
    IMAGE_TAG   = "latest"

    ECR_URI     = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

    ECS_CLUSTER = "my-ecs-cluster"
    ECS_SERVICE = "frontend-service1"
    TASK_FAMILY = "frontend-service"
}

stages {

    stage('Login to ECR') {
        steps {
            sh '''
            echo "Login to Amazon ECR"

            aws ecr get-login-password --region $AWS_REGION | \
            docker login --username AWS --password-stdin $ECR_URI
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

    stage('Tag Image') {
        steps {
            sh '''
            echo "Tagging image"

            docker tag $REPOSITORY:$IMAGE_TAG \
            $ECR_URI/$REPOSITORY:$IMAGE_TAG
            '''
        }
    }

    stage('Push Image to ECR') {
        steps {
            sh '''
            echo "Pushing image to ECR"

            docker push $ECR_URI/$REPOSITORY:$IMAGE_TAG
            '''
        }
    }

    stage('Fetch Task Definition') {
        steps {
            sh '''
            echo "Fetching current ECS task definition"

            aws ecs describe-task-definition \
            --task-definition $TASK_FAMILY \
            --query taskDefinition > task-def.json
            '''
        }
    }

    stage('Create New Revision') {
        steps {
            sh '''
            echo "Updating container image"

            cat task-def.json | jq \
            --arg IMAGE "$ECR_URI/$REPOSITORY:$IMAGE_TAG" \
            '.containerDefinitions[0].image=$IMAGE |
            del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)' \
            > new-task-def.json

            echo "Registering new revision"

            aws ecs register-task-definition \
            --cli-input-json file://new-task-def.json
            '''
        }
    }

    stage('Update ECS Service') {
        steps {
            sh '''
            echo "Getting latest revision"

            REVISION=$(aws ecs describe-task-definition \
            --task-definition $TASK_FAMILY \
            --query 'taskDefinition.revision' \
            --output text)

            echo "Deploying revision $REVISION"

            aws ecs update-service \
            --cluster $ECS_CLUSTER \
            --service $ECS_SERVICE \
            --task-definition $TASK_FAMILY:$REVISION \
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

}

