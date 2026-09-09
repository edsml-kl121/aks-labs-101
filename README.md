# aks-labs-101

Student-friendly setup for the [AKS Labs "Setting up the Lab Environment"](https://azure-samples.github.io/aks-labs/docs/getting-started/setting-up-lab-environment) guide.

The complete upstream [Kubernetes the Easy Way with AKS Automatic](docs/aks-automatic/index.mdx)
workshop and all of its referenced images are also vendored locally.

This repo turns that guide into a set of numbered bash scripts so you can set up
your Azure lab environment step by step, without copy-pasting commands from a
web page.

## Prerequisites

- An Azure subscription with permission to create resources.
- A GitHub account.
- A code editor (e.g. Visual Studio Code).
- The following command line tools installed (or use [Azure Cloud Shell](https://shell.azure.com/), which has them pre-installed):
  - [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
  - [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
  - Git
  - A Bash shell (Windows users: WSL or Azure Cloud Shell)

## Repo layout

```
config.env.example      # Template for your lab settings (resource group, region, cluster name)
.lab-state.env           # Auto-populated with values scripts need to share (deployment name, cluster name, etc.)
scripts/
  00-check-prerequisites.sh        # Verifies tools, Azure login, aks-preview extension, lists valid regions
  01-login-and-create-rg.sh        # az login + creates the resource group
  02-deploy-arm-template.sh        # Deploys shared Azure resources (Log Analytics, Monitor, ACR, Key Vault, etc.)
  03-create-aks-cluster.sh         # Creates the AKS cluster with best-practice settings
  04-add-user-nodepool-and-taint.sh # Adds a user node pool and taints the system node pool
  05-enable-monitoring.sh           # Enables Azure Monitor metrics + Container Insights logging
  06-deploy-demo-app.sh             # Deploys the AKS Store Demo sample application
  07-connect-azure-openai.sh        # Connects AKS to Azure OpenAI with workload identity
```

## How to run the lab

Run these steps in order, from the root of this repo.

### 1. Configure your settings

```bash
cp config.env.example config.env
```

Edit `config.env` and set `RG_NAME` (resource group name) and `LOCATION` (an Azure
region that supports availability zones). You can find valid regions in step 2 below.

Then load the settings into your shell:

```bash
source config.env
```

> You'll need to re-run `source config.env` (and `source .lab-state.env`, once it
> exists) any time you open a new terminal session.

### 2. Install prerequisites

```bash
./scripts/00-check-prerequisites.sh
```

On Ubuntu, WSL Ubuntu, or GitHub Codespaces, this installs Git, Azure CLI,
`kubectl`, and the `aks-preview` extension. It uses `sudo`, so enter your Linux
password if prompted. Already-installed Azure CLI and `kubectl` are left in place.

Azure Cloud Shell already includes these tools. On macOS or another Linux
distribution, use the installation links in the prerequisites section instead.

### 3. Log in and create the resource group

```bash
./scripts/01-login-and-create-rg.sh
```

Logs in via device code and creates the resource group from `config.env`.

### 4. Deploy shared Azure resources

```bash
./scripts/02-deploy-arm-template.sh
source .lab-state.env
```

Deploys (in the background) the Log Analytics Workspace, Azure Monitor Workspace,
Azure Container Registry, Key Vault, and a user-assigned
managed identity. This takes a few minutes to finish, so feel free to move on to
the next step while it completes. Remember to `source .lab-state.env` afterwards
so later scripts can find `DEPLOY_NAME`.

### 5. Create the AKS cluster

```bash
./scripts/03-create-aks-cluster.sh
source .lab-state.env
```

Creates an AKS cluster with a 3-node system pool, availability zones, Azure CNI
Overlay powered by Cilium, workload identity, and SSH access disabled. Takes 10+
minutes. Also configures `kubectl` to point at the new cluster.

### 6. Add a user node pool and taint the system pool

```bash
./scripts/04-add-user-nodepool-and-taint.sh
```

Adds a `userpool` node pool for application workloads and taints `systempool` so
only system components are scheduled there.

### 7. Enable monitoring and logging

```bash
./scripts/05-enable-monitoring.sh
```

Waits for the step 4 deployment to finish, reads its outputs, and enables Azure
Monitor metrics (Prometheus) and Container Insights logging on the
cluster.

### 8. Deploy the demo application

```bash
./scripts/06-deploy-demo-app.sh
```

Deploys the [AKS Store Demo](https://github.com/Azure-Samples/aks-store-demo)
sample e-commerce app into the `pets` namespace. If the service IP is still
`<pending>`, wait a few minutes and run:

```bash
kubectl get service store-front -n pets
```

Open `http://EXTERNAL-IP` after an IP appears.

### 9. Connect to Azure OpenAI

Choose either option:

- **Option A - Bash:** Run the automated script below.
- **Option B - Azure portal:** Follow the illustrated
  [Lab 7 portal click-through guide](docs/lab-7-azure-openai-portal.md). No Bash
  or terminal commands are required.

```bash
./scripts/07-connect-azure-openai.sh
```

This is the non-redundant portion of the
[AKS Automatic lab](https://azure-samples.github.io/aks-labs/docs/getting-started/aks-automatic/)
through a successful Azure OpenAI connection. It creates an Azure OpenAI account
and model deployment, reuses the managed identity from step 4, and configures an
AKS Service Connector connection with workload identity. It then sends a real
chat-completions request from a temporary pod in the `pets` namespace and prints
the model response.

The defaults match the referenced lab. You can override the model, version,
capacity, API version, or account name in `config.env`; model availability and
quota vary by subscription and region. No API keys are stored in Kubernetes.

## You're done!

Once the demo app is up, you have an AKS cluster with multiple node pools,
availability zones, monitoring configured, and a passwordless Azure OpenAI
connection, plus a sample app to experiment with. You can now proceed to any of the workshops in the
[AKS Labs](https://azure-samples.github.io/aks-labs/) site.

### Notes for instructors/students

- Not all production best practices are covered here (e.g. the cluster is
  publicly accessible, not a private cluster). See the source guide for details.
- Ensure your subscription has at least 32 vCPU of Standard D-series quota
  available; request an increase if `scripts/03-create-aks-cluster.sh` fails
  due to quota limits.
- If a specific workshop has its own AKS cluster creation steps, skip steps 5-7
  above and follow that workshop's instructions instead.