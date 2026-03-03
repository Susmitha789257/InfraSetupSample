#!/bin/bash

docker stop app1-container || true
docker rm app1-container || true

docker pull 860616632758.dkr.ecr.ap-northeast-3.amazonaws.com/app1-repo:latest

docker run -d -p 80:80 --name app1-container 860616632758.dkr.ecr.ap-northeast-3.amazonaws.com/app1-repo:latest
