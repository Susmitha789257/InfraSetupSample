#!/bin/bash

AWS_REGION=ap-northeast-3
ACCOUNT_ID=860616632758

docker login -u AWS -p $(aws ecr get-login-password --region $AWS_REGION) $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker network create app-network || true

echo "Stopping old containers..."

docker stop frontend backend mysql-db || true
docker rm frontend backend mysql-db || true

echo "Pulling images..."

docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/database-repo:latest
docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/backend-repo:latest
docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend-repo:latest

echo "Starting database..."

docker run -d \
--name mysql-db \
--network app-network \
-p 3306:3306 \
$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/database-repo:latest

echo "Starting backend..."

docker run -d \
--name backend \
--network app-network \
-p 8000:8000 \
$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/backend-repo:latest

echo "Starting frontend..."

docker run -d \
--name frontend \
--network app-network \
-p 80:80 \
$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend-repo:latest
