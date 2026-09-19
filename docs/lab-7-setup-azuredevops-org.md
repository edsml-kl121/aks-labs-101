# Set up an Azure DevOps organization for Lab 7

Complete these steps only if you do not already have an Azure DevOps
organization and project where you can create repositories and pipelines. When
setup is complete, continue with
[Lab 7: Connect AKS to Azure OpenAI with Azure DevOps](lab-7-azure-openai-portal-azure-devops.md).

## 1. Start Azure DevOps setup

1. Open [Azure DevOps](https://dev.azure.com/) and sign in.
2. If this is your first time using Azure DevOps, review the terms and optional
   communications setting, then select **Continue**.

![Get started with Azure DevOps](aks-automatic/azure-devops-assets/azure-devops-get-started.png)

## 2. Create an organization

1. Select **Create new organization**.

![Create an Azure DevOps organization](aks-automatic/azure-devops-assets/azure-devops-create-organization.png)

2. Enter a unique organization name.
3. Choose the region where your projects will be hosted.
4. Select the Azure subscription used for this lab, then select **Continue**.

![Configure the Azure DevOps organization](aks-automatic/azure-devops-assets/azure-devops-configure-organization.png)

## 3. Create a project

1. In the new organization, select **New project**.
2. Enter a project name, such as `aks-lab`.
3. Keep **Visibility** set to **Private**.
4. Select **Create**.
5. Confirm the project opens and the left menu includes **Repos** and
   **Pipelines**.

Your Azure DevOps organization and project are ready. Continue with the
[Azure DevOps Lab 7 guide](lab-7-azure-openai-portal-azure-devops.md).
