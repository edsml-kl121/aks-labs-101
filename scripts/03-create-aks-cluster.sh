#!/usr/bin/env bash
# Step 3: Create the AKS cluster with a system node pool, availability zones,
# Azure CNI Overlay powered by Cilium, and workload identity enabled.
set -euo pipefail

: "${RG_NAME:?RG_NAME is not set. Run 'source config.env' first.}"
: "${LOCATION:?LOCATION is not set. Run 'source config.env' first.}"
: "${AKS_CLUSTER_NAME:?AKS_CLUSTER_NAME is not set. Run 'source config.env' first.}"
: "${NODE_VM_SIZE:?NODE_VM_SIZE is not set. Run 'source config.env' first.}"

STATE_FILE="$(dirname "$0")/../.lab-state.env"

echo "==> Looking up the latest default Kubernetes version in ${LOCATION}..."
K8S_VERSION=$(az aks get-versions -l "${LOCATION}" \
  --query "reverse(sort_by(values[?isDefault==true].{version: version}, &version)) | [0]" \
  -o tsv)
echo "  Using Kubernetes version: ${K8S_VERSION}"
echo "  (Doing the cluster upgrades workshop? Pass an older version explicitly instead.)"

echo ""
echo "==> Creating AKS cluster '${AKS_CLUSTER_NAME}' (this can take 10+ minutes)..."
AKS_NAME=$(az aks create \
  --resource-group "${RG_NAME}" \
  --name "${AKS_CLUSTER_NAME}" \
  --location "${LOCATION}" \
  --tier standard \
  --kubernetes-version "${K8S_VERSION}" \
  --os-sku AzureLinux \
  --nodepool-name systempool \
  --node-count 3 \
  --node-vm-size "${NODE_VM_SIZE}" \
  --load-balancer-sku standard \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --network-dataplane cilium \
  --network-policy cilium \
  --ssh-access disabled \
  --enable-managed-identity \
  --enable-workload-identity \
  --enable-oidc-issuer \
  --enable-acns \
  --generate-ssh-keys \
  --query name -o tsv)

echo "export AKS_NAME=\"${AKS_NAME}\"" >> "${STATE_FILE}"

echo ""
echo "==> Fetching cluster credentials..."
az aks get-credentials \
  --resource-group "${RG_NAME}" \
  --name "${AKS_NAME}" \
  --overwrite-existing

echo ""
echo "Cluster '${AKS_NAME}' created and kubectl is configured."
echo "Next: run scripts/04-add-user-nodepool-and-taint.sh"
