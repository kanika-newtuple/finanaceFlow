GIT_ROOT := $(shell git rev-parse --show-toplevel)
create-network:
	docker network create -d bridge shared_network

start-services:
	docker compose -f docker-compose-services.yml up -d --build

stop-services:
	docker compose -f docker-compose-services.yml down

start-application:
	docker compose -f docker-compose-main.yml up -d --build

stop-application:
	docker compose -f docker-compose-main.yml down
