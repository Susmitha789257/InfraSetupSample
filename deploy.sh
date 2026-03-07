#!/bin/bash

AWS_REGION=ap-northeast-3
ACCOUNT_ID=860616632758

docker login -u AWS -p $(aws ecr get-login-password --region $AWS_REGION) $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend-repo:latest
docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/backend-repo:latest

docker stop frontend backend || true
docker rm frontend backend || true

docker run -d --name backend --network app-network -p 8000:8000 $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/backend-repo:latest
docker run -d --name frontend --network app-network -p 80:80 $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend-repo:latest
