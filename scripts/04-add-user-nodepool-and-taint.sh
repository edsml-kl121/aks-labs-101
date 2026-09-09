#!/usr/bin/env bash
# Step 4: Add a user node pool and taint the system node pool so that
# user workloads are only scheduled on the user node pool.
set -euo pipefail

: "${RG_NAME:?RG_NAME is not set. Run 'source config.env' first.}"
: "${AKS_NAME:?AKS_NAME is not set. Run 'source .lab-state.env' first.}"
: "${NODE_VM_SIZE:?NODE_VM_SIZE is not set. Run 'source config.env' first.}"

echo "==> Adding user node pool 'userpool'..."
az aks nodepool add \
  --resource-group "${RG_NAME}" \
  --cluster-name "${AKS_NAME}" \
  --mode User \
  --name userpool \
  --node-vm-size "${NODE_VM_SIZE}" \
  --node-count 1

echo ""
echo "==> Tainting the system node pool so only system pods are scheduled there..."
az aks nodepool update \
  --resource-group "${RG_NAME}" \
  --cluster-name "${AKS_NAME}" \
  --name systempool \
  --node-taints CriticalAddonsOnly=true:NoSchedule

echo ""
echo "User node pool added and system node pool tainted."
echo "Next: run scripts/05-enable-monitoring.sh"
