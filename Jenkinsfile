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

            docker build --no-cache -t $REPOSITORY:$IMAGE_TAG .
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
            echo "Pushing image"

            docker push $ECR_URI/$REPOSITORY:$IMAGE_TAG
            '''
        }
    }

    stage('Fetch Task Definition') {
        steps {
            sh '''
            echo "Fetching current task definition"

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

    stage('Delete ECS Service') {
        steps {
            sh '''
            echo "Deleting ECS service"

            aws ecs update-service \
            --cluster $ECS_CLUSTER \
            --service $ECS_SERVICE \
            --desired-count 0 || true

            aws ecs delete-service \
            --cluster $ECS_CLUSTER \
            --service $ECS_SERVICE \
            --force || true
            '''
        }
    }

    stage('Wait for Service Deletion') {
        steps {
            sh '''
            echo "Waiting for service to delete..."

            while aws ecs describe-services \
            --cluster $ECS_CLUSTER \
            --services $ECS_SERVICE \
            --query "services[0].status" \
            --output text 2>/dev/null | grep -q "DRAINING"
            do
                echo "Service still draining..."
                sleep 10
            done

            echo "Service fully deleted"
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

            echo "Creating ECS service with revision $REVISION"

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

