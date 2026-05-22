#!/usr/bin/env bash
set -euo pipefail

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"
LOCATION="${LOCATION:-eastus}"
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-rg-aks-acr-test}"
AKS_CLUSTER_NAME="${AKS_CLUSTER_NAME:-aks-minimal-test}"
DNS_PREFIX="${DNS_PREFIX:-aksminimaltest}"
UNIQUE_SUFFIX="${UNIQUE_SUFFIX:-$(date +%s)}"
ACR_NAME="${ACR_NAME:-acrtest${UNIQUE_SUFFIX}}"

if [[ -z "${SUBSCRIPTION_ID}" ]]; then
  echo "SUBSCRIPTION_ID is required."
  echo "Example: SUBSCRIPTION_ID=<your-subscription-id> ./deploy.sh"
  exit 1
fi

echo "Logging in to Azure..."
az login >/dev/null

echo "Setting subscription ${SUBSCRIPTION_ID}..."
az account set --subscription "${SUBSCRIPTION_ID}"

echo "Creating resource group ${RESOURCE_GROUP_NAME} in ${LOCATION}..."
az group create --name "${RESOURCE_GROUP_NAME}" --location "${LOCATION}" >/dev/null

echo "Deploying Bicep template at resource-group scope..."
az deployment group create \
  --name "aks-acr-minimal-$(date +%Y%m%d%H%M%S)" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --template-file ./main.bicep \
  --parameters \
      location="${LOCATION}" \
      aksClusterName="${AKS_CLUSTER_NAME}" \
      dnsPrefix="${DNS_PREFIX}" \
      acrName="${ACR_NAME}"

echo "Fetching AKS kubeconfig..."
az aks get-credentials \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${AKS_CLUSTER_NAME}" \
  --overwrite-existing

echo "Done."
echo "Resource Group: ${RESOURCE_GROUP_NAME}"
echo "AKS: ${AKS_CLUSTER_NAME}"
echo "ACR: ${ACR_NAME}"
