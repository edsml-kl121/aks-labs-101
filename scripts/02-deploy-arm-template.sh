#!/usr/bin/env bash
# Step 2: Deploy the ARM/Bicep template with the shared Azure resources
# (Log Analytics, Azure Monitor Workspace, ACR, Key Vault, Managed Identity).
set -euo pipefail

: "${RG_NAME:?RG_NAME is not set. Run 'source config.env' first.}"

STATE_FILE="$(dirname "$0")/../.lab-state.env"

echo "==> Getting your Azure AD object ID..."
USER_ID="$(az ad signed-in-user show --query id -o tsv)"

DEPLOY_NAME="labdemo$(date +%s)"

echo "==> Starting ARM template deployment '${DEPLOY_NAME}'..."
az deployment group create \
  --name "${DEPLOY_NAME}" \
  --resource-group "${RG_NAME}" \
  --template-uri https://raw.githubusercontent.com/azure-samples/aks-labs/refs/heads/main/docs/getting-started/assets/aks-labs-deploy.json \
  --parameters userObjectId="${USER_ID}" \
  --no-wait

{
  echo "export USER_ID=\"${USER_ID}\""
  echo "export DEPLOY_NAME=\"${DEPLOY_NAME}\""
} >> "${STATE_FILE}"

echo ""
echo "Deployment '${DEPLOY_NAME}' started in the background (--no-wait)."
echo "It can take a few minutes to finish. You can move on to creating the AKS cluster now."
echo "State saved to ${STATE_FILE} -- remember to 'source ${STATE_FILE}' in new terminal sessions."
echo "Next: run scripts/03-create-aks-cluster.sh"
