#!/usr/bin/env bash
# Step 5: Enable Azure Monitor metrics (Prometheus) and container
# insights logging on the AKS cluster, using the resources deployed in step 2.
set -euo pipefail

: "${RG_NAME:?RG_NAME is not set. Run 'source config.env' first.}"
: "${AKS_NAME:?AKS_NAME is not set. Run 'source .lab-state.env' first.}"
: "${DEPLOY_NAME:?DEPLOY_NAME is not set. Run 'source .lab-state.env' first.}"

echo "==> Waiting for ARM deployment '${DEPLOY_NAME}' to finish, if it hasn't already..."
az deployment group wait \
  --resource-group "${RG_NAME}" \
  --name "${DEPLOY_NAME}" \
  --created

echo ""
echo "==> Reading the monitoring resource IDs from the deployment..."
METRICS_WORKSPACE_ID=$(az deployment group show \
  --resource-group "${RG_NAME}" \
  --name "${DEPLOY_NAME}" \
  --query "properties.outputs.metricsWorkspaceId.value" \
  -o tsv)

LOG_WORKSPACE_ID=$(az deployment group show \
  --resource-group "${RG_NAME}" \
  --name "${DEPLOY_NAME}" \
  --query "properties.outputs.logWorkspaceId.value" \
  -o tsv)

echo ""
echo "==> Enabling Azure Monitor metrics (Prometheus)..."
az aks update \
  --resource-group "${RG_NAME}" \
  --name "${AKS_NAME}" \
  --enable-azure-monitor-metrics \
  --azure-monitor-workspace-resource-id "${METRICS_WORKSPACE_ID}"

echo ""
echo "==> Enabling the monitoring add-on (Container Insights logging)..."
az aks enable-addons \
  --resource-group "${RG_NAME}" \
  --name "${AKS_NAME}" \
  --addon monitoring \
  --workspace-resource-id "${LOG_WORKSPACE_ID}"

echo ""
echo "Monitoring and logging enabled."
echo "Next: run scripts/06-deploy-demo-app.sh"
