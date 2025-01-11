GIT_ROOT := $(shell git rev-parse --show-toplevel)
INFRA_ROOT := $(GIT_ROOT)/infra
RELEASE_VERSION := latest
VERSION := 0.0.1
REGISTRY_NAME := GenAI-ACR
AKS_CLUSTER_NAME := GenAI-AKS
AKS_RESOURCE_GROUP := GenAI
BOT_SERVICE_REPO_URL := $(REGISTRY_NAME).azurecr.io/bot-api-service
TESSERACT_REPO_URL := $(REGISTRY_NAME).azurecr.io/tesseract
NAMESPACE := pcr

AZ_FUNCTION_PROCESSOR_APP_NAME :=  GenAI-file-processor
AZ_FUNCTION_QUEUER_APP_NAME :=  GenAI-file-queuer
AZ_DOC_PROCESSOR_CONTAINER_APP_JOB := document-processor-job

acr-login:
	az acr login --name $(REGISTRY_NAME)

aks-login:
	az aks get-credentials --resource-group $(AKS_RESOURCE_GROUP) --name $(AKS_CLUSTER_NAME)

az-publish-function:
	cd ${GIT_ROOT}/az_func/file_processor/ && func azure functionapp publish ${AZ_FUNCTION_PROCESSOR_APP_NAME}
	cd ${GIT_ROOT}/az_func/file_queuer/ && func azure functionapp publish ${AZ_FUNCTION_QUEUER_APP_NAME}

build-bot-service:
	docker build --no-cache --progress=plain --platform=linux/amd64 -t bot_service:${VERSION} -f ${GIT_ROOT}/bot_service/dockerfiles/api.Dockerfile ${GIT_ROOT}/bot_service

build-tesseract:
	docker build --no-cache --progress=plain --platform=linux/amd64 -t tesseract:${VERSION} -f ${GIT_ROOT}/bot_service/dockerfiles/tesseract.Dockerfile ${GIT_ROOT}/bot_service

build-doc-processor:
	docker build --no-cache --progress=plain --platform=linux/amd64 -t doc_processor:${VERSION} -f ${GIT_ROOT}/bot_service/dockerfiles/doc_processing.Dockerfile ${GIT_ROOT}/bot_service

deploy-doc-processor:
	az containerapp job update \
		--resource-group ${AKS_RESOURCE_GROUP} \
		--name ${AZ_DOC_PROCESSOR_CONTAINER_APP_JOB} \
		--image $(shell echo ${REGISTRY_NAME}.azurecr.io/doc-processor:${RELEASE_VERSION} | tr '[:upper:]' '[:lower:]') \
		--cpu 4.0 \
		--memory 8.0Gi \
		--replica-timeout 1800 \
		--replica-retry-limit 1 \
		--replica-completion-count 1 \
		--parallelism 50 \
		--min-executions 0 \
		--max-executions 4 \
		--polling-interval 60 \
		--scale-rule-name azure-queue \
		--scale-rule-type azure-servicebus \
		--scale-rule-metadata namespace=newtuple queueName=pcr-dev messageCount=12 \
		--scale-rule-auth connection=queue

deploy-bot-service:
	cd ${GIT_ROOT}/infra/helm/bot_service && helm upgrade -i bot-service ${INFRA_ROOT}/helm/bot_service -f ${INFRA_ROOT}/helm/bot_service/values.yaml --namespace ${NAMESPACE} --create-namespace --debug --wait --set releases.version=${RELEASE_VERSION}

deploy-tesseract:
	cd ${GIT_ROOT}/infra/helm/tesseract && helm upgrade -i tesseract ${INFRA_ROOT}/helm/tesseract -f ${INFRA_ROOT}/helm/tesseract/values.yaml --namespace ${NAMESPACE} --create-namespace --debug --wait --set releases.version=${RELEASE_VERSION}

deploy-langfuse:
	cd ${GIT_ROOT}/infra/helm/langfuse-k8s  && helm dependency build
	cd ${GIT_ROOT}/infra/helm/langfuse-k8s && helm upgrade -i langfuse-k8s ${INFRA_ROOT}/helm/langfuse-k8s -f ${INFRA_ROOT}/helm/langfuse-k8s/values.yaml --namespace ${NAMESPACE} --create-namespace --debug --wait --set releases.version=${RELEASE_VERSION}

deploy-nginx-ingress:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update
	helm upgrade -i nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"="true"

deploy-pushgateway:
	cd ${GIT_ROOT}/infra/helm/pushgateway && helm upgrade -i pushgateway ${INFRA_ROOT}/helm/pushgateway \
		-f ${INFRA_ROOT}/helm/pushgateway/values.yaml \
		--namespace ${NAMESPACE} \
		--create-namespace \
		--debug \
		--wait \
		--set releases.version=${RELEASE_VERSION}

deploy-bot-service-lb:
	kubectl expose deployment bot-service-deployment  --type=LoadBalancer --name=bot-service-dev-lb --port=80 --target-port=8081 -n ${NAMESPACE}

deploy-tesseract-lb:
	kubectl expose deployment tesseract-deployment  --type=LoadBalancer --name=tesseract-lb --port=80 --target-port=8000 -n ${NAMESPACE}

deploy-langfuse-lb:
	kubectl expose deployment langfuse-k8s  --type=LoadBalancer --name=langfuse-k8s-lb --port=80 --target-port=3000 -n ${NAMESPACE}

deploy-pushgateway-lb:
	kubectl expose deployment pushgateway-deployment  --type=LoadBalancer --name=pushgateway-lb --port=80 --target-port=9091 -n ${NAMESPACE}


push-docker-bot-service:
	docker tag bot_service:${VERSION} ${BOT_SERVICE_REPO_URL}:${RELEASE_VERSION}
	docker push ${BOT_SERVICE_REPO_URL}:${RELEASE_VERSION}

push-docker-tesseract:
	docker tag tesseract:${VERSION} ${TESSERACT_REPO_URL}:${RELEASE_VERSION}
	docker push ${TESSERACT_REPO_URL}:${RELEASE_VERSION}

push-docker-doc-processor:
	docker tag doc_processor:${VERSION} ${REGISTRY_NAME}.azurecr.io/doc-processor:${RELEASE_VERSION}
	docker push ${REGISTRY_NAME}.azurecr.io/doc-processor:${RELEASE_VERSION}

mega-deploy-bot-service:
	make build-bot-service
	make push-docker-bot-service
	make deploy-bot-service
	kubectl rollout restart deployment/bot-service-deployment -n ${NAMESPACE}

mega-deploy-tesseract:
	make build-tesseract
	make push-docker-tesseract
	make deploy-tesseract
	kubectl rollout restart deployment/tesseract-deployment -n ${NAMESPACE}

mega-deploy-doc-processor:
	make build-doc-processor
	make push-docker-doc-processor
	make deploy-doc-processor

mega-deploy-pushgateway:
	make deploy-pushgateway
	kubectl rollout restart deployment/pushgateway-deployment -n ${NAMESPACE}


# kubectl exec -it tesseract-deployment-5b5c576b55-v5c6w -n pcr -- bash
