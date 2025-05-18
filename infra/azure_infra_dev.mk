# ----------------------
# COLORS
# ----------------------
# ANSI color codes
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m # No Color
BOLD := \033[1m

# ----------------------
# ROOT CONFIG
# ----------------------
GIT_ROOT := $(shell git rev-parse --show-toplevel)
INFRA_ROOT := $(GIT_ROOT)/infra
ETC_ROOT := $(GIT_ROOT)/bot_service/src/backend/etc

RELEASE_VERSION := $(shell git describe --tags --abbrev=0)
VERSION := latest

REGISTRY_NAME := docsdevacr2

AKS_CLUSTER_NAME := docs-dev-aks
AKS_RESOURCE_GROUP := docs-dev-rg
BOT_SERVICE_REPO_URL := $(REGISTRY_NAME).azurecr.io/bot-api-service
NAMESPACE := pcr-dev
KEY_VAULT_NAME := docs-dev-kv

BOT_SERVICE_REPO_URL := $(shell echo ${REGISTRY_NAME}.azurecr.io/bot-api-service:${RELEASE_VERSION} | tr '[:upper:]' '[:lower:]')
DOC_PROCESSOR_CONTAINER_APP_JOB_REPO_URL := $(shell echo ${REGISTRY_NAME}.azurecr.io/doc-processor:${RELEASE_VERSION} | tr '[:upper:]' '[:lower:]')

ENV_FILE := $(ETC_ROOT)/.env
ENV_PAIRS := $(shell ./kv.sh parse_env_file $(ENV_FILE))


AZ_FUNCTION_PROCESSOR_APP_NAME := docs-dev-GenAI-file-processor1
AZ_FUNCTION_DEADLETTER_HANDLER_APP_NAME := docs-dev-GenAI-document-handler1
AZ_DOC_PROCESSOR_CONTAINER_APP_JOB_SHORT := dev-shortdoc-processor-job
AZ_DOC_PROCESSOR_CONTAINER_APP_JOB_LONG := dev-longdoc-processor-job

QUEUE_NAMESPACE := docs-dev-sb-namespace
SHORT_DOC_PROCESSING_QUEUE_NAME := docs-dev-short-doc-queue
LONG_DOC_PROCESSING_QUEUE_NAME := docs-dev-long-doc-queue
SHORT_FORM_MESSAGE_COUNT := 15
LONG_FORM_MESSAGE_COUNT := 1


# ----------------------
# ACR and AKS
# ----------------------

get-release-version:
	@echo  "${BLUE}Current release:${NC} ${GREEN}${RELEASE_VERSION}${NC}"

acr-login:
	az acr login --name $(REGISTRY_NAME)

aks-login:
	az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME} --format azure --overwritexisting
	export KUBECONFIG=$HOME/.kube/config
	kubelogin convert-kubeconfig -l azurecli

# ----------------------
# Azure Functions
# ----------------------
az-publish-function:
	cd ${GIT_ROOT}/az_func/file_processor/ && \
		func azure functionapp publish ${AZ_FUNCTION_PROCESSOR_APP_NAME} --python
	cd ${GIT_ROOT}/az_func/deadletter_handler/ && \
		func azure functionapp publish ${AZ_FUNCTION_DEADLETTER_HANDLER_APP_NAME} --python


# ----------------------
# Docker Builds
# ----------------------
build-bot-service:
	docker build --no-cache --progress=plain --platform=linux/amd64 \
		-t bot_service:${VERSION} \
		-f ${GIT_ROOT}/bot_service/dockerfiles/api.Dockerfile \
		${GIT_ROOT}/bot_service


build-doc-processor:
	docker build --no-cache --progress=plain --platform=linux/amd64 \
		-t doc_processor:${VERSION} \
		-f ${GIT_ROOT}/bot_service/dockerfiles/doc_processing.Dockerfile \
		${GIT_ROOT}/bot_service

# ----------------------
# Docker Push
# (lowercase domain fixes the "uppercase" and "unauthorized" problem)
# ----------------------
push-docker-bot-service:
	az acr login -n ${REGISTRY_NAME}
	# Force registry domain to lowercase on tag/push
	docker tag bot_service:${VERSION} ${BOT_SERVICE_REPO_URL}
	docker push ${BOT_SERVICE_REPO_URL}


push-docker-doc-processor:
	az acr login -n ${REGISTRY_NAME}
	docker tag doc_processor:${VERSION} ${DOC_PROCESSOR_CONTAINER_APP_JOB_REPO_URL}
	docker push ${DOC_PROCESSOR_CONTAINER_APP_JOB_REPO_URL}

# ----------------------
# Helm Deploys
# ----------------------
deploy-doc-processor:
	az containerapp job update \
		--resource-group ${AKS_RESOURCE_GROUP} \
		--name ${AZ_DOC_PROCESSOR_CONTAINER_APP_JOB_SHORT} \
		--image ${DOC_PROCESSOR_CONTAINER_APP_JOB_REPO_URL} \
		--cpu 4.0 \
		--memory 8.0Gi \
		--replica-timeout 3600 \
		--replica-retry-limit 1 \
		--replica-completion-count 1 \
		--parallelism 50 \
		--minxecutions 0 \
		--maxxecutions 8 \
		--polling-interval 3600 \
		--scale-rule-name azure-queue \
		--scale-rule-type azure-servicebus \
		--scale-rule-metadata namespace=${QUEUE_NAMESPACE} queueName=${SHORT_DOC_PROCESSING_QUEUE_NAME} messageCount=${SHORT_FORM_MESSAGE_COUNT} \
		--scale-rule-auth connection=queue-connection \
		--setnv-vars PROCESSING_MODE=short

	
	az containerapp job update \
		--resource-group ${AKS_RESOURCE_GROUP} \
		--name ${AZ_DOC_PROCESSOR_CONTAINER_APP_JOB_LONG} \
		--image ${DOC_PROCESSOR_CONTAINER_APP_JOB_REPO_URL} \
		--cpu 4.0 \
		--memory 8.0Gi \
		--replica-timeout 4500 \
		--replica-retry-limit 1 \
		--replica-completion-count 1 \
		--parallelism 50 \
		--minxecutions 0 \
		--maxxecutions 8 \
		--polling-interval 4500 \
		--scale-rule-name azure-queue \
		--scale-rule-type azure-servicebus \
		--scale-rule-metadata namespace=${QUEUE_NAMESPACE} queueName=${LONG_DOC_PROCESSING_QUEUE_NAME} messageCount=${LONG_FORM_MESSAGE_COUNT} \
		--scale-rule-auth connection=queue-connection \
		--setnv-vars PROCESSING_MODE=long

deploy-bot-service:
	cd ${GIT_ROOT}/infra/helm/bot_service && \
		helm upgrade -i bot-service ${INFRA_ROOT}/helm/bot_service \
		-f ${INFRA_ROOT}/helm/bot_service/values.yaml \
		--namespace ${NAMESPACE} \
		--create-namespace \
		--debug \
		--wait \
		--set releases.version=${RELEASE_VERSION}



deploy-langfuse:
	helm repo add langfuse https://langfuse.github.io/langfuse-k8s 
	cd ${GIT_ROOT}/infra/helm/langfuse-k8s && ls && \
		helm upgrade -i langfuse-k8s ${INFRA_ROOT}/helm/langfuse-k8s \
		-f ${INFRA_ROOT}/helm/langfuse-k8s/values.yaml \
		--namespace ${NAMESPACE} \
		--create-namespace \
		--debug \
		--wait 

deploy-nginx-ingress:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update
	helm upgrade -i nginx-ingress ingress-nginx/ingress-nginx \
		--namespace ingress-nginx \
		--create-namespace \
		--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"="true"

deploy-pushgateway:
	cd ${GIT_ROOT}/infra/helm/pushgateway && \
		helm upgrade -i pushgateway prometheus-community/prometheus-pushgateway \
		-f ${INFRA_ROOT}/helm/pushgateway/values.yaml \
		--namespace ${NAMESPACE} \
		--create-namespace \
		--debug \
		--wait 

# ----------------------
# Expose Load Balancers
# ----------------------
deploy-bot-service-lb:
	kubectl expose deployment bot-service-deployment \
		--type=LoadBalancer \
		--name=bot-service-dev-lb \
		--port=80 \
		--target-port=8081 \
		-n ${NAMESPACE}



deploy-langfuse-lb:
	kubectl expose deployment langfuse-k8s \
		--type=LoadBalancer \
		--name=langfuse-k8s-lb \
		--port=80 \
		--target-port=3000 \
		-n ${NAMESPACE}

deploy-pushgateway-lb:
	kubectl expose deployment pushgateway-deployment \
		--type=LoadBalancer \
		--name=pushgateway-lb \
		--port=80 \
		--target-port=9091 \
		-n ${NAMESPACE}

.SILENT:
update-vault-secrets:
	@echo  "${YELLOW}Updating secrets in ${BOLD}${KEY_VAULT_NAME}${NC} ..."
	./kv.sh set_key_vault_secrets ${KEY_VAULT_NAME} ${ENV_FILE}

.SILENT:
update-doc-processornv:
	az containerapp job update \
		--resource-group ${AKS_RESOURCE_GROUP} \
		--name ${AZ_DOC_PROCESSOR_CONTAINER_APP_JOB_SHORT} \
		--setnv-vars ${ENV_PAIRS}

	az containerapp job update \
		--resource-group ${AKS_RESOURCE_GROUP} \
		--name ${AZ_DOC_PROCESSOR_CONTAINER_APP_JOB_LONG} \
		--setnv-vars ${ENV_PAIRS}


# ----------------------
# Mega / Composite Targets
# ----------------------
mega-deploy-bot-service:
	@echo  "${BOLD}${BLUE}====== DEPLOYING BOT SERVICE ======${NC}"
	@echo  "${CYAN}Step 1/5:${NC} ${GREEN}ACR Login${NC}"
	make -f dev.mk acr-login
	@echo  "${CYAN}Step 2/5:${NC} ${GREEN}Building Bot Service${NC}"
	make -f dev.mk build-bot-service
	@echo  "${CYAN}Step 3/5:${NC} ${GREEN}Pushing Bot Service Docker Image${NC}"
	make -f dev.mk push-docker-bot-service
	@echo  "${CYAN}Step 4/5:${NC} ${GREEN}Deploying Bot Service${NC}"
	make -f dev.mk deploy-bot-service
	@echo  "${CYAN}Step 5/5:${NC} ${GREEN}Restarting Deployment${NC}"
	kubectl rollout restart deployment/bot-service-deployment -n ${NAMESPACE}
	@echo  "${BOLD}${GREEN}✓ Bot Service deployed successfully!${NC}"



mega-deploy-doc-processor:
	@echo  "${BOLD}${BLUE}====== DEPLOYING DOCUMENT PROCESSOR ======${NC}"
	@echo  "${CYAN}Step 1/4:${NC} ${GREEN}ACR Login${NC}"
	make -f dev.mk acr-login
	@echo  "${CYAN}Step 2/4:${NC} ${GREEN}Building Document Processor${NC}"
	make -f dev.mk build-doc-processor
	@echo  "${CYAN}Step 3/4:${NC} ${GREEN}Pushing Document Processor Docker Image${NC}"
	make -f dev.mk push-docker-doc-processor
	@echo  "${CYAN}Step 4/4:${NC} ${GREEN}Deploying Document Processor${NC}"
	make -f dev.mk deploy-doc-processor
	@echo  "${BOLD}${GREEN}✓ Document Processor deployed successfully!${NC}"

mega-deploy-pushgateway:
	@echo  "${BOLD}${BLUE}====== DEPLOYING PUSHGATEWAY ======${NC}"
	@echo  "${CYAN}Step 1/2:${NC} ${GREEN}Deploying Pushgateway${NC}"
	make -f dev.mk deploy-pushgateway
	@echo  "${CYAN}Step 2/2:${NC} ${GREEN}Restarting Deployment${NC}"
	kubectl rollout restart deployment/pushgateway-deployment -n ${NAMESPACE}
	@echo  "${BOLD}${GREEN}✓ Pushgateway deployed successfully!${NC}"

mega-deploy-langfuse:
	@echo  "${BOLD}${BLUE}====== DEPLOYING LANGFUSE ======${NC}"
	@echo  "${CYAN}Step 1/2:${NC} ${GREEN}Deploying Langfuse${NC}"
	make -f dev.mk deploy-langfuse
	@echo  "${CYAN}Step 2/2:${NC} ${GREEN}Restarting Deployment${NC}"
	kubectl rollout restart deployment/langfuse-k8s -n ${NAMESPACE}
	@echo  "${BOLD}${GREEN}✓ Langfuse deployed successfully!${NC}"

# ----------------------
# Test Targets
# ----------------------
test-acr-access:
	az acr login --name $(REGISTRY_NAME)
	az acr repository list --name $(REGISTRY_NAME)

test-aks-access:
	make -f dev.mk aks-login
	kubectl get nodes -n $(NAMESPACE)
	kubectl get pods -n $(NAMESPACE)

test-bot-service:
	kubectl get deployment bot-service-deployment -n $(NAMESPACE)
	kubectl get service bot-service-dev-lb -n $(NAMESPACE)

test-doc-processor:
	az containerapp job show \
		--name $(AZ_DOC_PROCESSOR_CONTAINER_APP_JOB_SHORT) \
		--resource-group $(AKS_RESOURCE_GROUP)

	az containerapp job show \
		--name $(AZ_DOC_PROCESSOR_CONTAINER_APP_JOB_LONG) \
		--resource-group $(AKS_RESOURCE_GROUP)

test-all:
	@echo  "${BOLD}${CYAN}=== Testing release ===${NC}"
	@make -f dev.mk get-release-version
	@echo  "${BOLD}${CYAN}=== Testing ACR access ===${NC}"
	@make -f dev.mk test-acr-access
	@echo  "\n${BOLD}${CYAN}=== Testing AKS access ===${NC}"
	@make -f dev.mk test-aks-access
	# @echo  "\n${BOLD}${CYAN}=== Testing Bot Service deployment ===${NC}"
	# @make -f dev.mk test-bot-service
	@echo  "\n${BOLD}${CYAN}=== Testing Document Processor ===${NC}"
	@make -f dev.mk test-doc-processor

mega-deploy-all:
	@echo  "${BOLD}${PURPLE}========== MEGA DEPLOYMENT STARTED ===========${NC}"
	@echo  "${CYAN}[1/5]${NC} ${GREEN}Logging into AKS${NC}"
	make -f dev.mk aks-login
	@echo  "${CYAN}[2/5]${NC} ${GREEN}Running tests${NC}"
	make -f dev.mk test-all
	@echo  "${CYAN}[3/5]${NC} ${GREEN}Publishing Azure Functions${NC}"
	make -f dev.mk az-publish-function
	@echo  "${CYAN}[4/5]${NC} ${GREEN}Deploying Bot Service${NC}"
	make -f dev.mk mega-deploy-bot-service
	@echo  "${CYAN}[5/5]${NC} ${GREEN}Deploying Document Processor${NC}"
	make -f dev.mk mega-deploy-doc-processor
	@echo  "${BOLD}${GREEN}✓ All services deployed successfully!${NC}"
	@echo  "${BOLD}${PURPLE}========== MEGA DEPLOYMENT COMPLETED ===========${NC}"

# ----------------------
# Help Target
# ----------------------
.PHONY: help
help:
	@echo  "${BOLD}${BLUE}===============================================${NC}"
	@echo  "${BOLD}${BLUE}         Azure Infrastructure Makefile        ${NC}"
	@echo  "${BOLD}${BLUE}===============================================${NC}"
	
	@echo  "${BOLD}Available commands:${NC}"
	@echo  "${YELLOW}Basic Commands:${NC}"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk get-release-version${NC}        - Display current release version"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk acr-login${NC}                  - Login to Azure Container Registry"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk aks-login${NC}                  - Login to Azure Kubernetes Service"
	
	@echo  "\n${YELLOW}Deployment Commands:${NC}"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk mega-deploy-all${NC}            - Deploy all services"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk mega-deploy-pushgateway${NC}    - Deploy Pushgateway"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk mega-deploy-langfuse${NC}       - Deploy Langfuse"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk az-publish-function${NC}        - Publish Azure Functions"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk update-vault-secrets${NC}       - Update secrets in Azure Key Vault"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk mega-deploy-bot-service${NC}    - Deploy bot service"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk mega-deploy-doc-processor${NC}  - Deploy document processor"
	
	@echo  "\n${YELLOW}Testing Commands:${NC}"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk test-all${NC}                   - Run all tests"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk test-acr-access${NC}            - Test ACR access"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk test-aks-access${NC}            - Test AKS access"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk test-bot-service${NC}           - Test bot service"
	@echo  "  ${GREEN}make -f azure_infra_dev.mk test-doc-processor${NC}         - Test document processor"

# Add help as default target
.DEFAULT_GOAL := help