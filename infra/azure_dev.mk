# ----------------------
# ROOT CONFIG
# ----------------------
GIT_ROOT := $(shell git rev-parse --show-toplevel)
INFRA_ROOT := $(GIT_ROOT)/infra
ETC_ROOT := $(GIT_ROOT)/bot_service/src/backend/etc

RELEASE_VERSION := $(shell git describe --tags --abbrev=0)
VERSION := latest

# If your ACR is truly named "PCRGenAIACR" in Azure, its domain is "pcrgeniacr.azurecr.io"
REGISTRY_NAME := docsprodacr2

AKS_CLUSTER_NAME := docs-prod-aks
AKS_RESOURCE_GROUP := docs-prod-rg
BOT_SERVICE_REPO_URL := $(REGISTRY_NAME).azurecr.io/bot-api-service
NAMESPACE := pcr-prod
KEY_VAULT_NAME := docs-prod-kv

BOT_SERVICE_REPO_URL := $(shell echo ${REGISTRY_NAME}.azurecr.io/bot-api-service:${RELEASE_VERSION} | tr '[:upper:]' '[:lower:]')
DOC_PROCESSOR_CONTAINER_APP_JOB_REPO_URL := $(shell echo ${REGISTRY_NAME}.azurecr.io/doc-processor:${RELEASE_VERSION} | tr '[:upper:]' '[:lower:]')

ENV_FILE := $(ETC_ROOT)/.env
ENV_PAIRS := $(shell ./kv.sh parse_env_file $(ENV_FILE))


AZ_FUNCTION_PROCESSOR_APP_NAME := docs-prod-GenAI-file-processor1
AZ_FUNCTION_DEADLETTER_HANDLER_APP_NAME := docs-prod-GenAI-document-handler1
AZ_DOC_PROCESSOR_CONTAINER_APP_JOB_SHORT := prod-shortdoc-processor-job
AZ_DOC_PROCESSOR_CONTAINER_APP_JOB_LONG := prod-longdoc-processor-job

QUEUE_NAMESPACE := docs-prod-sb-namespace
SHORT_DOC_PROCESSING_QUEUE_NAME := docs-prod-short-doc-queue
LONG_DOC_PROCESSING_QUEUE_NAME := docs-prod-long-doc-queue
SHORT_FORM_MESSAGE_COUNT := 15
LONG_FORM_MESSAGE_COUNT := 1


# ----------------------
# ACR and AKS
# ----------------------

get-release-version:
	echo "Current realease: ${RELEASE_VERSION}"

acr-login:
	az acr login --name $(REGISTRY_NAME)

aks-login:
	az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME} --format azure --overwrite-existing
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
		--min-executions 0 \
		--max-executions 8 \
		--polling-interval 3600 \
		--scale-rule-name azure-queue \
		--scale-rule-type azure-servicebus \
		--scale-rule-metadata namespace=${QUEUE_NAMESPACE} queueName=${SHORT_DOC_PROCESSING_QUEUE_NAME} messageCount=${SHORT_FORM_MESSAGE_COUNT} \
		--scale-rule-auth connection=queue-connection \
		--set-env-vars PROCESSING_MODE=short

	
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
		--min-executions 0 \
		--max-executions 8 \
		--polling-interval 4500 \
		--scale-rule-name azure-queue \
		--scale-rule-type azure-servicebus \
		--scale-rule-metadata namespace=${QUEUE_NAMESPACE} queueName=${LONG_DOC_PROCESSING_QUEUE_NAME} messageCount=${LONG_FORM_MESSAGE_COUNT} \
		--scale-rule-auth connection=queue-connection \
		--set-env-vars PROCESSING_MODE=long

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
	echo "Updating secrets in ${KEY_VAULT_NAME} ..."
	./kv.sh set_key_vault_secrets ${KEY_VAULT_NAME} ${ENV_FILE}

.SILENT:
update-doc-processor-env:
	az containerapp job update \
		--resource-group ${AKS_RESOURCE_GROUP} \
		--name ${AZ_DOC_PROCESSOR_CONTAINER_APP_JOB_SHORT} \
		--set-env-vars ${ENV_PAIRS}

	az containerapp job update \
		--resource-group ${AKS_RESOURCE_GROUP} \
		--name ${AZ_DOC_PROCESSOR_CONTAINER_APP_JOB_LONG} \
		--set-env-vars ${ENV_PAIRS}


# ----------------------
# Mega / Composite Targets
# ----------------------
mega-deploy-bot-service:
	make -f prod.mk acr-login
	make -f prod.mk build-bot-service
	make -f prod.mk push-docker-bot-service
	make -f prod.mk deploy-bot-service
	kubectl rollout restart deployment/bot-service-deployment -n ${NAMESPACE}



mega-deploy-doc-processor:
	make -f prod.mk acr-login
	make -f prod.mk build-doc-processor
	make -f prod.mk push-docker-doc-processor
	make -f prod.mk deploy-doc-processor

mega-deploy-pushgateway:
	make -f prod.mk deploy-pushgateway
	kubectl rollout restart deployment/pushgateway-deployment -n ${NAMESPACE}

mega-deploy-langfuse:
	make -f prod.mk deploy-langfuse
	kubectl rollout restart deployment/langfuse-k8s -n ${NAMESPACE}

# ----------------------
# Test Targets
# ----------------------
test-acr-access:
	az acr login --name $(REGISTRY_NAME)
	az acr repository list --name $(REGISTRY_NAME)

test-aks-access:
	make -f prod.mk aks-login
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
	@echo "Testing release..."
	@make -f prod.mk get-release-version
	@echo "Testing ACR access..."
	@make -f prod.mk test-acr-access
	@echo "\nTesting AKS access..."
	@make -f prod.mk test-aks-access
	# @echo "\nTesting Bot Service deployment..."
	# @make -f prod.mk test-bot-service
	@echo "\nTesting Document Processor..."
	@make -f prod.mk test-doc-processor

mega-deploy-all:
	make -f prod.mk aks-login
	make -f prod.mk test-all
	make -f prod.mk az-publish-function
	make -f prod.mk mega-deploy-bot-service
	make -f prod.mk mega-deploy-doc-processor