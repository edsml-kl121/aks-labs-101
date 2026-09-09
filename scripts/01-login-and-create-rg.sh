#!/usr/bin/env bash
# Step 1: Log in to Azure and create the resource group for the lab.
set -euo pipefail

: "${RG_NAME:?RG_NAME is not set. Run 'source config.env' first.}"
: "${LOCATION:?LOCATION is not set. Run 'source config.env' first.}"

echo "==> Logging in to Azure (follow the device code prompt)..."
az login --use-device-code

echo ""
echo "==> Creating resource group '${RG_NAME}' in '${LOCATION}'..."
az group create \
  --name "${RG_NAME}" \
  --location "${LOCATION}"

echo ""
echo "Resource group ready. Next: run scripts/02-deploy-arm-template.sh"
