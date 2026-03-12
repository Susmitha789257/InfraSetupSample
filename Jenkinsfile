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
            aws ecr get-login-password --region $AWS_REGION | \
            docker login --username AWS --password-stdin $ECR_URI
            '''
        }
    }

    stage('Build Docker Image') {
        steps {
            sh '''
            docker build -t $REPOSITORY:$IMAGE_TAG .
            '''
        }
    }

    stage('Tag Image') {
        steps {
            sh '''
            docker tag $REPOSITORY:$IMAGE_TAG \
            $ECR_URI/$REPOSITORY:$IMAGE_TAG
            '''
        }
    }

    stage('Push Image') {
        steps {
            sh '''
            docker push $ECR_URI/$REPOSITORY:$IMAGE_TAG
            '''
        }
    }

    stage('Fetch Task Definition') {
        steps {
            sh '''
            aws ecs describe-task-definition \
            --task-definition $TASK_FAMILY \
            --query taskDefinition > task-def.json
            '''
        }
    }

    stage('Create New Revision') {
        steps {
            sh '''
            cat task-def.json | jq \
            --arg IMAGE "$ECR_URI/$REPOSITORY:$IMAGE_TAG" \
            '.containerDefinitions[0].image=$IMAGE |
            del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)' \
            > new-task-def.json

            aws ecs register-task-definition \
            --cli-input-json file://new-task-def.json
            '''
        }
    }

    stage('Delete ECS Service') {
        steps {
            sh '''
            echo "Deleting existing ECS service"

            aws ecs update-service \
            --cluster $ECS_CLUSTER \
            --service $ECS_SERVICE \
            --desired-count 0

            aws ecs delete-service \
            --cluster $ECS_CLUSTER \
            --service $ECS_SERVICE \
            --force
            '''
        }
    }

    stage('Wait 15 seconds') {
        steps {
            sh '''
            echo "Waiting for service deletion..."
            sleep 15
            '''
        }
    }

    stage('Recreate ECS Service') {
        steps {
            sh '''
            REVISION=$(aws ecs describe-task-definition \
            --task-definition $TASK_FAMILY \
            --query 'taskDefinition.revision' \
            --output text)

            echo "Creating new ECS service with revision $REVISION"

            aws ecs create-service \
            --cluster $ECS_CLUSTER \
            --service-name $ECS_SERVICE \
            --task-definition $TASK_FAMILY:$REVISION \
            --desired-count 1 \
            --launch-type EC2
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

