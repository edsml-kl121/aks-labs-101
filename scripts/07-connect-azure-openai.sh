#!/usr/bin/env bash
# Step 7: Create Azure OpenAI resources, connect AKS with workload identity,
# and verify the connection with a real request from inside the cluster.
set -euo pipefail

: "${RG_NAME:?RG_NAME is not set. Run 'source config.env' first.}"
: "${LOCATION:?LOCATION is not set. Run 'source config.env' first.}"

AKS_NAME="${AKS_NAME:-${AKS_CLUSTER_NAME:-}}"
: "${AKS_NAME:?AKS_NAME is not set. Run 'source .lab-state.env' first.}"

AOAI_MODEL_NAME="${AOAI_MODEL_NAME:-gpt-5.4-mini}"
AOAI_MODEL_VERSION="${AOAI_MODEL_VERSION:-2026-03-17}"
AOAI_MODEL_DEPLOYMENT="${AOAI_MODEL_DEPLOYMENT:-${AOAI_MODEL_NAME}}"
AOAI_MODEL_CAPACITY="${AOAI_MODEL_CAPACITY:-1}"
AOAI_API_VERSION="${AOAI_API_VERSION:-2024-12-01-preview}"
AOAI_CONNECTION_NAME="${AOAI_CONNECTION_NAME:-azure-openai}"
NAMESPACE="pets"

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
if [[ -z "${AOAI_ACCOUNT_NAME:-}" ]]; then
  ACCOUNT_SUFFIX=$(printf '%s' "${SUBSCRIPTION_ID}:${RG_NAME}" | sha256sum | cut -c1-10)
  AOAI_ACCOUNT_NAME="myopenai${ACCOUNT_SUFFIX}"
fi

echo "==> Ensuring Azure OpenAI account '${AOAI_ACCOUNT_NAME}' exists..."
if ! az cognitiveservices account show \
  --resource-group "${RG_NAME}" \
  --name "${AOAI_ACCOUNT_NAME}" \
  --output none 2>/dev/null; then
  az cognitiveservices account create \
    --resource-group "${RG_NAME}" \
    --name "${AOAI_ACCOUNT_NAME}" \
    --location "${LOCATION}" \
    --kind OpenAI \
    --sku S0 \
    --custom-domain "${AOAI_ACCOUNT_NAME}"
fi

echo "==> Checking model availability..."
MODEL_AVAILABLE=$(az cognitiveservices account list-models \
  --resource-group "${RG_NAME}" \
  --name "${AOAI_ACCOUNT_NAME}" \
  --query "[?name=='${AOAI_MODEL_NAME}' && version=='${AOAI_MODEL_VERSION}'] | length(@)" \
  -o tsv)
if [[ "${MODEL_AVAILABLE}" == "0" ]]; then
  echo "Model ${AOAI_MODEL_NAME} version ${AOAI_MODEL_VERSION} is not available for this account." >&2
  echo "List available versions with:" >&2
  echo "az cognitiveservices account list-models -g ${RG_NAME} -n ${AOAI_ACCOUNT_NAME} --query \"[?name=='${AOAI_MODEL_NAME}'].version\" -o tsv" >&2
  exit 1
fi

echo "==> Ensuring model deployment '${AOAI_MODEL_DEPLOYMENT}' exists..."
if ! az cognitiveservices account deployment show \
  --resource-group "${RG_NAME}" \
  --name "${AOAI_ACCOUNT_NAME}" \
  --deployment-name "${AOAI_MODEL_DEPLOYMENT}" \
  --output none 2>/dev/null; then
  az cognitiveservices account deployment create \
    --resource-group "${RG_NAME}" \
    --name "${AOAI_ACCOUNT_NAME}" \
    --deployment-name "${AOAI_MODEL_DEPLOYMENT}" \
    --model-format OpenAI \
    --model-name "${AOAI_MODEL_NAME}" \
    --model-version "${AOAI_MODEL_VERSION}" \
    --sku-name GlobalStandard \
    --sku-capacity "${AOAI_MODEL_CAPACITY}"
fi

echo "==> Selecting the user-assigned managed identity..."
if [[ -n "${MANAGED_IDENTITY_NAME:-}" ]]; then
  IDENTITY_ID=$(az identity show \
    --resource-group "${RG_NAME}" \
    --name "${MANAGED_IDENTITY_NAME}" \
    --query id -o tsv)
else
  IDENTITY_COUNT=$(az identity list --resource-group "${RG_NAME}" --query 'length(@)' -o tsv)
  if [[ "${IDENTITY_COUNT}" != "1" ]]; then
    echo "Expected one managed identity in ${RG_NAME}, found ${IDENTITY_COUNT}." >&2
    echo "Set MANAGED_IDENTITY_NAME in config.env to select one." >&2
    az identity list --resource-group "${RG_NAME}" --query '[].name' -o tsv >&2
    exit 1
  fi
  IDENTITY_ID=$(az identity list --resource-group "${RG_NAME}" --query '[0].id' -o tsv)
fi
IDENTITY_CLIENT_ID=$(az identity show --ids "${IDENTITY_ID}" --query clientId -o tsv)

echo "==> Installing the Service Connector passwordless extension..."
az extension add --name serviceconnector-passwordless --upgrade --yes

echo "==> Creating the passwordless AKS Service Connector connection..."
if ! az aks connection show \
  --resource-group "${RG_NAME}" \
  --name "${AKS_NAME}" \
  --connection "${AOAI_CONNECTION_NAME}" \
  --output none 2>/dev/null; then
  az aks connection create cognitiveservices \
    --resource-group "${RG_NAME}" \
    --name "${AKS_NAME}" \
    --connection "${AOAI_CONNECTION_NAME}" \
    --target-resource-group "${RG_NAME}" \
    --account "${AOAI_ACCOUNT_NAME}" \
    --kube-namespace "${NAMESPACE}" \
    --client-type none \
    --workload-identity "${IDENTITY_ID}"
fi

az aks connection validate \
  --resource-group "${RG_NAME}" \
  --name "${AKS_NAME}" \
  --connection "${AOAI_CONNECTION_NAME}" \
  --output none

echo "==> Locating the Service Connector service account..."
SERVICE_ACCOUNT=$(kubectl get serviceaccounts -n "${NAMESPACE}" \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.azure\.workload\.identity/client-id}{"\n"}{end}' \
  | awk -v client_id="${IDENTITY_CLIENT_ID}" '$2 == client_id {print $1; exit}')
if [[ -z "${SERVICE_ACCOUNT}" ]]; then
  echo "Service Connector did not create a service account for identity ${IDENTITY_CLIENT_ID}." >&2
  exit 1
fi

AOAI_ENDPOINT=$(az cognitiveservices account show \
  --resource-group "${RG_NAME}" \
  --name "${AOAI_ACCOUNT_NAME}" \
  --query properties.endpoint -o tsv)

echo "==> Sending a test request from AKS..."
kubectl delete pod azure-openai-connection-test -n "${NAMESPACE}" --ignore-not-found
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: azure-openai-connection-test
  namespace: ${NAMESPACE}
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: ${SERVICE_ACCOUNT}
  restartPolicy: Never
  containers:
    - name: test
      image: mcr.microsoft.com/azure-cli:2.77.0
      command: ["/bin/sh", "-c"]
      args:
        - |
          set -eu
          az login --service-principal \
            --username "\${AZURE_CLIENT_ID}" \
            --tenant "\${AZURE_TENANT_ID}" \
            --federated-token "\$(cat "\${AZURE_FEDERATED_TOKEN_FILE}")" \
            --output none
          token="\$(az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv)"
          curl --fail-with-body --silent --show-error \
            -H "Authorization: Bearer \${token}" \
            -H "Content-Type: application/json" \
            -d '{"messages":[{"role":"user","content":"Reply with exactly: Azure OpenAI connection successful"}],"max_completion_tokens":30}' \
            "${AOAI_ENDPOINT}openai/deployments/${AOAI_MODEL_DEPLOYMENT}/chat/completions?api-version=${AOAI_API_VERSION}"
EOF

if ! kubectl wait pod/azure-openai-connection-test \
  -n "${NAMESPACE}" \
  --for=jsonpath='{.status.phase}'=Succeeded \
  --timeout=5m; then
  kubectl logs azure-openai-connection-test -n "${NAMESPACE}" || true
  exit 1
fi

kubectl logs azure-openai-connection-test -n "${NAMESPACE}"
kubectl delete pod azure-openai-connection-test -n "${NAMESPACE}" --wait=false

echo ""
echo "Azure OpenAI successfully connected from AKS using workload identity."