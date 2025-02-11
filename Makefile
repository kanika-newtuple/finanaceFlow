GIT_ROOT := $(shell git rev-parse --show-toplevel)
DEV_GIT_BRANCH := main
PROD_GIT_BRANCH := prod
.PHONY: docs

help:
	@echo "Available commands:"
	@echo " - docs                 		: Generate local documentation in the /docs folder using MkDocs."
	@echo " - deploy-docs          		: Deploy the generated documentation to GitHub Pages."
	@echo " - pre-commit           		: Install and run pre-commit hooks for code quality checks."
	@echo " - add-alembic-revision 		: Auto-generate an Alembic revision for database migrations."
	@echo " - create-network       		: Create the required Docker networks."
	@echo " - stop-services        		: Stop all running Docker services as defined in docker-compose-services.yml."
	@echo " - start-services       		: Stop then start all services with rebuild in detached mode."
	@echo " - stop-dev-application 		: Shut down the development instance of the application."
	@echo " - start-dev-application		: Start the development instance of the application with rebuild."
	@echo " - stop-prod-application		: Stop the production instance of the application."
	@echo " - start-prod-application    		: Start the production instance of the application with rebuild."
	@echo " - clean-docker-cache        		: Prune Docker build cache and builder cache."
	@echo " - sync-uv-dependencies      		: Synchronize the uv package dependencies by updating requirements."
	@echo " - install-dependencies			: Install Python dependencies from requirements.txt for local run."
	@echo " - tests				: Run tests using pytest."
	@echo " - run-application-backend		: Run the application backend locally."
	@echo " - run-application-frontend		: Run the application frontend locally."

add-alembic-revision:
	@echo "Auto-generating an Alembic revision for database migrations...\n"
	cd ${GIT_ROOT}/bot_service/src/backend && alembic revision --autogenerate

clean-docker-cache:
	@echo "Pruning Docker build cache and builder cache...\n"
	docker buildx prune -a -f
	docker builder prune -a -f

create-network:
	@echo "Creating Docker networks...\n"
	docker network create -d bridge shared_network
	docker network create -d bridge llm-network

docs:
	@echo "Generating local documentation...\n"
	pip3 install mkdocs-material --quiet 
	python3 -m mkdocs serve -a localhost:8001

deploy-docs:
	@echo "Deploying documentation to GitHub Pages...\n"
	pip3 install mkdocs-material --quiet 
	python3 -m mkdocs gh-deploy --force

pre-commit:
	@echo "Installing and running pre-commit hooks...\n"
	pip3 install pre-commit --quiet
	pre-commit install
	cd ${GIT_ROOT} && pre-commit run --all-files


run-application-backend:
	@echo "Running the application backend locally...\n"
	pip3 install -r ${GIT_ROOT}/bot_service/src/backend/requirements.txt -U
	@echo "Running the application...\n"
	python3 ${GIT_ROOT}/bot_service/src/backend/main.py

run-application-frontend:
	@echo "Running the application frontend locally ...\n"
	cd ${GIT_ROOT}/bot_service/src/frontend && npm install && npm start


stop-services:
	@echo "Stopping Docker services...\n"
	docker compose -f docker-compose-services.yml down

start-services:	stop-services
	@echo "Starting Docker services...\n"
	docker compose -f docker-compose-services.yml up -d --build

stop-dev-application:
	@echo "Shutting down the development instance of the application...\n"
	docker compose --project-name bot_${DEV_GIT_BRANCH} -f docker-compose-main.yml down

start-dev-application:	stop-dev-application
	@echo "Starting the development instance of the application...\n"
	docker compose --project-name bot_${DEV_GIT_BRANCH} -f docker-compose-main.yml up -d --build

stop-prod-application:
	@echo "Stopping the production instance of the application...\n"
	docker compose --project-name bot_${PROD_GIT_BRANCH} -f docker-compose-prod.yml down

start-prod-application:	stop-prod-application
	@echo "Starting the production instance of the application...\n"
	docker compose --project-name bot_${PROD_GIT_BRANCH} -f docker-compose-prod.yml up -d --build

sync-uv-depenencies:
	@echo "Synchronizing uv package dependencies...\n"
	pip3 install uv --quiet
	cd ${GIT_ROOT}/bot_service/src/backend && uv pip compile requirements.txt -o requirements.in

tests:
	@echo "Running tests...\n"
	pytest ${GIT_ROOT}/bot_service/src/backend/tests -v 