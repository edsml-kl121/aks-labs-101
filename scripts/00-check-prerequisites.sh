#!/usr/bin/env bash
# Step 0: Install the command line tools needed for the lab on Ubuntu.
set -euo pipefail

echo "==> Installing curl and Git..."
sudo apt-get update
sudo apt-get install --yes curl git

if ! command -v az >/dev/null 2>&1; then
  echo ""
  echo "==> Installing Azure CLI..."
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo ""
  echo "==> Installing kubectl..."
  sudo az aks install-cli
fi

echo ""
echo "==> Installed tool versions:"
az version
kubectl version --client
git --version

echo ""
echo "==> Installing or updating the aks-preview extension..."
az extension add --name aks-preview --upgrade

echo ""
echo "Prerequisite installation complete."
echo "Next: source config.env and run scripts/01-login-and-create-rg.sh"
