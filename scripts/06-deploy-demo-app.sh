#!/usr/bin/env bash
# Step 6: Deploy the AKS Store Demo application into the "pets" namespace.
set -euo pipefail

echo "==> Creating the 'pets' namespace..."
kubectl create namespace pets --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "==> Deploying the AKS Store Demo application..."
kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/refs/heads/main/aks-store-quickstart.yaml -n pets

echo ""
echo "==> Current resources in the 'pets' namespace:"
kubectl get all -n pets

echo ""
echo "==> Store-front service:"
kubectl get service store-front -n pets

echo ""
echo "The EXTERNAL-IP may show <pending> for a few minutes."
echo "Run this command again until an IP appears:"
echo "kubectl get service store-front -n pets"
echo "Then open http://EXTERNAL-IP in your browser."
