#!/bin/bash

AWS_REGION=ap-northeast-3
ACCOUNT_ID=860616632758

echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "Creating network..."
docker network create app-network || true

echo "Stopping old containers..."
docker stop frontend backend mysql-db || true
docker rm frontend backend mysql-db || true

echo "Pulling images..."
docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/database:latest
docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/backend:latest
docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend:latest


echo "Starting database..."
docker run -d \
--name mysql-db \
--network app-network \
-p 3306:3306 \
$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/database:latest

sleep 15

DB_STATUS=$(docker inspect -f '{{.State.Running}}' mysql-db)

if [ "$DB_STATUS" != "true" ]; then
  echo "Database failed to start. Deployment stopped."
  exit 1
fi

echo "Database running successfully."


echo "Starting backend..."
docker run -d \
--name backend \
--network app-network \
-p 8000:8000 \
$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/backend:latest

sleep 10

BACKEND_STATUS=$(docker inspect -f '{{.State.Running}}' backend)

if [ "$BACKEND_STATUS" != "true" ]; then
  echo "Backend failed to start. Deployment stopped."
  exit 1
fi

echo "Backend running successfully."


echo "Starting frontend..."
docker run -d \
--name frontend \
--network app-network \
-p 80:80 \
$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend:latest

sleep 5

FRONTEND_STATUS=$(docker inspect -f '{{.State.Running}}' frontend)

if [ "$FRONTEND_STATUS" != "true" ]; then
  echo "Frontend failed to start."
  exit 1
fi

echo "Deployment completed successfully."
