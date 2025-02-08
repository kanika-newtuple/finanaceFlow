#!/bin/bash

# main = dev
# prod = prod
# docker compose --project-name bot -f docker-compose-services.yml up --build -d

fetch_latest_changes(){
    git config user.email "deploy@deploy.com"
    git config user.name "deploy"

    # fetch latest changes on current working branch
    branch=$(git rev-parse --abbrev-ref HEAD)
    echo "Fetching & pulling latest code on $1";
    git pull origin $1
}

deploy_ci(){
    echo  "Stop existing services on compose project $1";
    docker compose --project-name bot_$1 -f docker-compose-$1.yml down

    echo "Cleaning cache build for older than 10 days for $1 "
    docker builder prune -f --filter until=240h
    docker buildx prune -f --filter until=240h
    docker image prune -a -f

    echo "Rebuilding services for bot $1";
    docker compose --project-name bot_$1 -f docker-compose-$1.yml up --build -d
}

"$@"
