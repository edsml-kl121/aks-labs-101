# Lab 7: Connect AKS to Azure OpenAI with Azure DevOps

This is the Azure DevOps and Azure portal path for AKS Automatic and Azure OpenAI. It imports
the Contoso Air application into Azure Repos, deploys it to the existing lab AKS
cluster with Azure Automated Deployments, and connects the application to Azure
OpenAI. You do not need Bash, Azure CLI, or `kubectl`.

The screenshots below come from the
[AKS Automatic lab](https://azure-samples.github.io/aks-labs/docs/getting-started/aks-automatic/).
This option follows the source lab's `dev` namespace and Contoso Air
application.

## Before you start

You should already have:

- The Azure resource group and shared resources from the earlier lab steps.
- The existing AKS cluster provisioned in the earlier lab steps.
- A user-assigned managed identity whose name normally begins with `myidentity`.
- An Azure DevOps organization and a project where you can create repositories
   and pipelines. If needed, complete
   [Set up an Azure DevOps organization for Lab 7](lab-7-setup-azuredevops-org.md)
   first.
- **Contributor** and **User Access Administrator** roles on the lab resource
  group.

The **DevHub GitHub OAuth** role is not needed for this exercise.

> Azure OpenAI model availability and quota vary by subscription and region.
> This path creates an Azure OpenAI account and model deployment. These
> resources may incur charges, but the path reuses the existing AKS cluster.

## 1. Create an Azure OpenAI resource

1. Open the [Azure portal](https://portal.azure.com/).
2. In the top search box, enter **Azure OpenAI**.
3. Select **Azure OpenAI**, then select **Create**.
4. On **Basics**, enter:

   | Setting | Value |
   | --- | --- |
   | Subscription | The subscription used for this lab |
   | Resource group | The resource group used for this lab |
   | Region | Prefer the same region as the AKS cluster |
   | Name | A globally unique name, such as `myopenai-<your initials>` |
   | Pricing tier | `Standard S0` |

5. Select **Next** through the remaining tabs. Leave public network access
   enabled for this lab.
6. Select **Review + submit**, then **Create**.
7. When deployment finishes, select **Go to resource**.

## 2. Deploy a chat model

1. On the Azure OpenAI resource overview, select **Go to Azure AI Foundry
   portal**. If that button is not shown, open
   [Azure AI Foundry](https://ai.azure.com/) and select the Azure OpenAI
   resource.
2. Select **Model deployments** or **Deployments**.
3. Select **Deploy model** > **Deploy base model**.
4. Select `gpt-5.4-mini`. If it is unavailable, choose another chat-completion
   model available in your region and subscription.
5. Set the deployment name to the model name, then select **Deploy**. Keep the
   default deployment type and use the smallest available capacity for the lab.
6. Open the deployment in the **Chat playground**, send a short message, and
   confirm the model replies. This verifies the Azure OpenAI deployment itself.

Keep the Azure OpenAI resource name and model deployment name available for the
next section.

## 3. Import Contoso Air into Azure Repos

1. Open [Azure DevOps](https://dev.azure.com/) and select your organization and
   project.
2. In your project, select **Repos** > **Files**.
3. From the repository selector, select **Import repository**. If the project
   has no repository, select **Import** on the welcome page.
4. Enter these values:

   | Setting | Value |
   | --- | --- |
   | Repository type | **Git** |
   | Clone URL | `https://github.com/Azure-Samples/contoso-air.git` |
   | Name | `contoso-air` |

![Import Contoso Air into Azure Repos](aks-automatic/azure-devops-assets/azure-devops-import-contoso-air-repository.png)

5. Select **Import** and wait for the `main` branch to appear.
6. Confirm that `src/web/Dockerfile` exists in the imported repository.

## 4. Start an Automated Deployment

1. Sign in to the [Azure portal](https://portal.azure.com/).
2. Search for **Kubernetes services** and open it.
3. Select **+ Create** > **Deploy application**.

![Deploy application with Automated Deployments](aks-automatic/assets/deploy-app.png)

4. On **Basics**, select **Deploy your application**.
5. Select the lab subscription and resource group.
6. Set **Workflow name** to `contoso-air-<your-name>`, replacing
   `<your-name>` with your name (for example, `contoso-air-alex`).
7. Select **Authorize access** if Azure asks for access to Azure DevOps.

![Select Azure DevOps as the repository location](aks-automatic/azure-devops-assets/aks-deploy-application-azure-devops.png)

8. Select your Azure DevOps organization, project, `contoso-air` repository,
   and the `main` branch.

![Select the Azure DevOps repository](aks-automatic/azure-devops-assets/aks-deploy-application-repository-details.png)

9. Select **Next**.

## 5. Configure the application image

On the **Application** tab, configure **Image**:

| Setting | Value |
| --- | --- |
| Container configuration | **Existing Dockerfile** |
| Dockerfile | Select `src/web/Dockerfile` from the repository browser |
| Dockerfile build context | `./src/web` |
| Azure Container Registry | Select the registry in the lab resource group |
| Azure Container Registry image | Select **Create new**, then enter `contoso-air` |

![Select the Contoso Air Dockerfile](aks-automatic/assets/deploy-app-image-path.png)

![Configure the container image](aks-automatic/assets/deploy-app-image.png)

Under **Deployment configuration**, enter:

| Setting | Value |
| --- | --- |
| Deployment options | **Generate application deployment files** |
| Save files in repository | Select the repository **Root** folder |
| Application port | `3000` |

![Configure the generated manifest](aks-automatic/assets/deploy-app-manifest-path.png)

Select **Next**.

## 6. Select the existing AKS cluster

1. Under **Cluster configuration**, select **Existing AKS Cluster**. Do not
   create another AKS cluster.
2. Select the lab subscription, resource group, and existing AKS cluster.

![Select the existing AKS cluster](aks-automatic/assets/Deploy%20an%20application.png)

3. For **Namespace**, select **Create new** and enter `dev`.

![Create the dev namespace](aks-automatic/assets/deploy-app-cluster-namespace.png)

4. Leave the monitoring and logging options enabled. Select the existing lab
   monitoring resources when offered.
5. Select **Next**.
6. Review the generated Dockerfile and Kubernetes deployment files.

![Review the Automated Deployment](aks-automatic/assets/deploy-app-review.png)

7. Select **Deploy**. Keep the browser page open while Azure prepares the Azure
   Pipeline and application deployment. This can take up to 20 minutes.

![Deploy the application](aks-automatic/assets/deploy-app-deploy.png)

## 7. Review and merge the generated pull request

1. When deployment setup completes, select **Approve pull request**.

   Azure DevOps opens the generated pull request for the deployment files.

   ![Generated Azure Pipeline pull request](aks-automatic/azure-devops-assets/azure-devops-generated-pipeline-pull-request.png)

2. Select the pull request's **Files** tab and review the generated pipeline and
   Kubernetes manifest files.

![Review the generated Azure Pipeline files](aks-automatic/azure-devops-assets/azure-devops-generated-pipeline-files.png)

3. In **Repos** > **Files**, switch to the pull request's source branch. Open
   the generated file under `.pipelines`, select **Edit**, locate
   `buildContextPath`, and set its value to `./src/web`:

   ```yaml
   buildContextPath: ./src/web
   ```

![Correct the pipeline build context](aks-automatic/azure-devops-assets/azure-devops-edit-pipeline-build-context.png)

4. Select **Commit**, enter a comment such as `Update pipeline build context`,
   and commit the change to the pull request's source branch.
5. Open `manifests/deployment.yaml`, select **Edit**, and locate the
   `SYS_PTRACE` capability. AKS Automatic deployment safeguards block this
   capability, so remove the `SYS_PTRACE` line.

![Edit the generated deployment manifest](aks-automatic/azure-devops-assets/azure-devops-edit-deployment-manifest.png)

6. Select **Commit**, enter a comment such as `Update deployment manifest`, and
   commit the change to the same source branch.

![Commit the deployment manifest change](aks-automatic/azure-devops-assets/azure-devops-commit-deployment-manifest.png)

7. Return to the pull request, select **Approve**, and then select **Complete**.
   Review the merge options and select **Complete merge** to merge the changes
   into `main`.

![Complete the generated pipeline pull request](aks-automatic/azure-devops-assets/azure-devops-complete-pipeline-pull-request.png)

8. Open **Pipelines** and select the generated pipeline run started by the
   merge.

![Open the generated Azure Pipeline run](aks-automatic/azure-devops-assets/azure-devops-generated-pipeline-run.png)

9. If the run reports that permission is needed to access the generated Azure
   service connection, open the permission check and select **Permit**. Confirm
   the permission, then rerun the pipeline if it does not resume automatically.

![Permit the generated service connection](aks-automatic/azure-devops-assets/azure-devops-permit-service-connection.png)

10. Wait until both the **Build stage** and **Deploy stage** succeed. This
    normally takes several minutes.

![Successful Azure Pipeline run](aks-automatic/azure-devops-assets/azure-devops-successful-pipeline-run.png)

The `buildContextPath` value is required because the Contoso Air Dockerfile and
its build context are under `src/web` rather than the repository root.

## 8. Test Contoso Air before connecting it

1. In the Azure portal, open the existing lab AKS cluster.
2. Select **Kubernetes resources** > **Services and ingresses**.
3. Select the external IP for the `contoso-air` service.

![Contoso Air external IP](aks-automatic/assets/contoso-air-service-ip.png)

4. In Contoso Air, select **Ask the AI travel assistant** and send a message.
   The initial request should report that the chat provider is not configured.

![Chat provider is not configured](aks-automatic/assets/ask-ai-travel-assistant-response.png)

## 9. Configure Contoso Air for Azure OpenAI

1. Return to the AKS Automatic cluster in the Azure portal.
2. Select **Kubernetes resources** > **Configuration**.
3. Filter by the `dev` namespace and open `contoso-air-config`.
4. Select **YAML** and add these entries under `data`:

```yaml
AZURE_OPENAI_API_VERSION: 2024-12-01-preview
AZURE_OPENAI_DEPLOYMENT: gpt-5.4-mini
CHAT_PROVIDER: azure
LOG_CHAT: 'true'
```

Use your actual model deployment name if you did not deploy `gpt-5.4-mini`.

![Edit the Contoso Air ConfigMap](aks-automatic/assets/contoso-air-config-edit.png)

5. Select **Review + save**, confirm the manifest changes, and select **Save**.

## 10. Open Service Connector

1. Return to the [Azure portal](https://portal.azure.com/).
2. Open the existing lab AKS cluster selected in step 6.
3. In the cluster menu, select **Settings** > **Service Connector**.
4. Select **+ Create**.

![AKS Service Connector page](aks-automatic/assets/service-connector.png)

## 11. Select Azure OpenAI

On the **Basics** tab, enter:

| Setting | Value |
| --- | --- |
| Kubernetes namespace | `dev` |
| Service type | **OpenAI Service** |
| Subscription | The subscription used for this lab |
| OpenAI | The Azure OpenAI resource created in step 1 |

Select **Next: Authentication**.

![Service Connector basics](aks-automatic/assets/service-connector-basics.png)

## 12. Configure workload identity

1. Select **Workload Identity**.
2. Select the user-assigned managed identity created by the shared-resources
   deployment. Its name normally begins with `myidentity`.
3. Expand **Advanced** and confirm that **Cognitive Services OpenAI
   Contributor** is the assigned role.
4. Do not select secret-based authentication. No Azure OpenAI API key is needed.
5. Select **Next: Networking**.

![Select workload identity](aks-automatic/assets/service-connector-auth.png)

The advanced view shows the Azure role and the connection settings that Service
Connector will add to Kubernetes.

![Service Connector advanced settings](aks-automatic/assets/service-connector-advanced.png)

## 13. Create the connection

1. On **Networking**, keep the default public-network option for this lab, then
   select **Next: Review + create**.
2. Confirm that the namespace is `dev`, authentication is **Workload
   Identity**, and the correct Azure OpenAI account is selected.
3. Select **Create**. Provisioning can take several minutes.

![Review the Service Connector connection](aks-automatic/assets/service-connector-review.png)

When creation finishes, return to **Settings** > **Service Connector** and open
the connection. Confirm that its provisioning or connection status is
**Succeeded**. If the page offers **Validate**, select it and confirm validation
succeeds.

Service Connector has now:

- Granted the managed identity access to Azure OpenAI.
- Created a federated identity credential for the `dev` namespace.
- Created a Kubernetes service account linked to the managed identity.
- Added the non-secret Azure OpenAI connection settings to Kubernetes.

## 14. Attach the connection to Contoso Air

1. On the **Service Connector** page, select the checkbox beside the OpenAI
   connection and select **YAML snippet**.

![Open the YAML snippet](aks-automatic/assets/service-connector-yaml-snippet.png)

2. For **Resource type**, select **Kubernetes Workload**.
3. For **Kubernetes Workload**, select `contoso-air`.

![Select the Contoso Air workload](aks-automatic/assets/service-connector-yaml-deploy.png)

4. Review the highlighted service account, workload identity label, and
   connection-setting changes.
5. Select **Apply**. Wait one or two minutes for the deployment rollout.

![Apply the workload identity configuration](aks-automatic/assets/service-connector-yaml-highlights.png)

## 15. Verify Azure OpenAI from the application

1. Return to the Contoso Air browser tab and refresh it.
2. Select **Ask the AI travel assistant**.
3. Ask the assistant to find a flight.
4. Confirm it returns an AI-generated response without a provider or
   authentication error.

![Successful Contoso Air Azure OpenAI chat](aks-automatic/assets/contoso-air-chat.png)

## Connection complete

The successful Contoso Air response confirms the full path: Azure Pipelines
deployed the application to AKS Automatic, Service Connector configured workload
identity, and the application authenticated to the Azure OpenAI model without an
API key.