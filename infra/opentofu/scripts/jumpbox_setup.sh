#!/bin/bash

# Log setup process
exec > >(tee -a /var/log/jumpbox-setup.log) 2>&1
echo "[$(date)] Starting jumpbox setup..."

# Set environment variables - these will be replaced by Terraform
RESOURCE_GROUP="${RESOURCE_GROUP}"
ADMIN_USERNAME="${ADMIN_USERNAME}"
TENANT_ID="${TENANT_ID}"

# Update package repositories
echo "[$(date)] Updating package repositories..."
apt-get update

# Install common packages
echo "[$(date)] Installing common tools and utilities..."
apt-get install -y apt-transport-https ca-certificates curl software-properties-common jq unzip git tmux make

# Install Docker using get-docker.sh script
echo "[$(date)] Installing Docker using get-docker.sh..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -a -G docker ${ADMIN_USERNAME}

# Install kubectl
echo "[$(date)] Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm through apt repository
echo "[$(date)] Installing Helm through apt repository..."
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get install -y helm

# Install Azure CLI
echo "[$(date)] Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install AKS CLI tools, including kubelogin
echo "[$(date)] Installing AKS CLI tools and kubelogin..."
az aks install-cli

# Install additional utility tools
echo "[$(date)] Installing additional utility tools..."
apt-get install -y python3-pip dnsutils

# Download Azure utilities for convenience
echo "[$(date)] Setting up helper scripts..."
cat > /home/${ADMIN_USERNAME}/get-aks-credentials.sh << EOF
#!/bin/bash
az login
az account set --subscription \$(az account list --query "[?isDefault].id" -o tsv)
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name \$1 --admin
echo "AKS credentials configured successfully"
EOF

cat > /home/${ADMIN_USERNAME}/acr-login.sh << EOF
#!/bin/bash
az login
az acr login --name \$1
echo "Logged into ACR: \$1"
EOF

# Add script for service principal authentication
cat > /home/${ADMIN_USERNAME}/setup-sp-auth.sh << EOF
#!/bin/bash
# This script helps setup Service Principal authentication for kubelogin
# Usage: ./setup-sp-auth.sh <cluster-name> <service-principal-id> <service-principal-secret>

if [ "\$#" -ne 3 ]; then
	echo "Usage: \$0 <cluster-name> <service-principal-id> <service-principal-secret>"
	exit 1
fi

CLUSTER_NAME=\$1
SP_ID=\$2
SP_SECRET=\$3

# Export env variables for kubelogin
export AAD_SERVICE_PRINCIPAL_CLIENT_ID=\$SP_ID
export AAD_SERVICE_PRINCIPAL_CLIENT_SECRET=\$SP_SECRET

# Generate kubeconfig for service principal
az login --service-principal -u \$SP_ID -p \$SP_SECRET --tenant ${TENANT_ID}
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name \$CLUSTER_NAME --overwrite-existing

echo "Service Principal authentication setup complete"
echo "You can now use 'kubelogin convert-kubeconfig -l spn' for non-interactive login"
EOF

# Create a bash profile with aliases and environment variables
cat > /home/${ADMIN_USERNAME}/.bash_aliases << 'EOF'
# Kubernetes aliases
alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
alias kdel='kubectl delete'
alias kdes='kubectl describe'
alias klog='kubectl logs'
alias kex='kubectl exec -it'

# Azure CLI aliases
alias azl='az login'
alias azs='az account set --subscription'
alias azls='az account list --output table'
alias azaks='az aks'
alias azacr='az acr'
alias azkv='az keyvault'

# Docker aliases
alias di='docker images'
alias dp='docker ps'
alias dex='docker exec -it'
alias dl='docker logs'

# System aliases
alias ll='ls -la'
alias cls='clear'
alias mk='make'
EOF

# Make scripts executable and set proper ownership
chmod +x /home/${ADMIN_USERNAME}/get-aks-credentials.sh
chmod +x /home/${ADMIN_USERNAME}/acr-login.sh
chmod +x /home/${ADMIN_USERNAME}/setup-sp-auth.sh
chown ${ADMIN_USERNAME}:${ADMIN_USERNAME} /home/${ADMIN_USERNAME}/get-aks-credentials.sh
chown ${ADMIN_USERNAME}:${ADMIN_USERNAME} /home/${ADMIN_USERNAME}/acr-login.sh
chown ${ADMIN_USERNAME}:${ADMIN_USERNAME} /home/${ADMIN_USERNAME}/setup-sp-auth.sh
chown ${ADMIN_USERNAME}:${ADMIN_USERNAME} /home/${ADMIN_USERNAME}/.bash_aliases

# Add environment variables to .bashrc
cat >> /home/${ADMIN_USERNAME}/.bashrc << EOF
export RESOURCE_GROUP="${RESOURCE_GROUP}"
export PATH=\$PATH:/home/${ADMIN_USERNAME}/.azure-kubectl
export PATH=\$PATH:/home/${ADMIN_USERNAME}/.azure-kubelogin

# Display welcome message
echo ""
echo "Welcome to the GenAIDocs Jumpbox"
echo "--------------------------------"
echo "Run './get-aks-credentials.sh <cluster-name>' to configure kubectl"
echo "Run './acr-login.sh <acr-name>' to log in to ACR"
echo ""
echo "Useful environment variables:"
echo "  RESOURCE_GROUP: \$RESOURCE_GROUP"
echo ""
echo "Tools installed:"
echo "  - Docker"
echo "  - kubectl"
echo "  - Helm"
echo "  - Azure CLI"
echo "  - kubelogin"
echo "  - make"
echo ""
echo "Use 'k' as shorthand for kubectl (see .bash_aliases for more shortcuts)"
EOF

# Create directories that might be useful
mkdir -p /home/${ADMIN_USERNAME}/deployments
mkdir -p /home/${ADMIN_USERNAME}/scripts
mkdir -p /home/${ADMIN_USERNAME}/manifests
chown -R ${ADMIN_USERNAME}:${ADMIN_USERNAME} /home/${ADMIN_USERNAME}/deployments
chown -R ${ADMIN_USERNAME}:${ADMIN_USERNAME} /home/${ADMIN_USERNAME}/scripts
chown -R ${ADMIN_USERNAME}:${ADMIN_USERNAME} /home/${ADMIN_USERNAME}/manifests

# Create a basic Makefile to help with common operations
cat > /home/${ADMIN_USERNAME}/Makefile << EOF
.PHONY: login aks-login acr-login get-aks-creds update-deps help

login:
	az login

aks-login: login
	@read -p "Enter AKS cluster name: " cluster_name; \\
	az aks get-credentials --resource-group ${RESOURCE_GROUP} --name \$\$cluster_name --admin

acr-login: login
	@read -p "Enter ACR name: " acr_name; \\
	az acr login --name \$\$acr_name

get-aks-creds:
	@read -p "Enter AKS cluster name: " cluster_name; \\
	./get-aks-credentials.sh \$\$cluster_name

update-deps:
	sudo apt-get update && sudo apt-get upgrade -y

help:
	@echo "Available make targets:"
	@echo "  login        - Log in to Azure CLI"
	@echo "  aks-login    - Log in to Azure CLI and get AKS credentials (prompts for cluster name)"
	@echo "  acr-login    - Log in to Azure CLI and Azure Container Registry (prompts for ACR name)"
	@echo "  get-aks-creds - Run the get-aks-credentials.sh script (prompts for cluster name)"
	@echo "  update-deps  - Update system dependencies"
EOF

chown ${ADMIN_USERNAME}:${ADMIN_USERNAME} /home/${ADMIN_USERNAME}/Makefile

echo "[$(date)] Jumpbox setup complete!"


# Install Azure Functions Core Tools
echo "[$(date)] Installing Azure Functions Core Tools..."
wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update
apt-get install -y azure-functions-core-tools-4
rm packages-microsoft-prod.deb

# Notify that Azure Functions Core Tools is installed
echo "[$(date)] Azure Functions Core Tools installed successfully"