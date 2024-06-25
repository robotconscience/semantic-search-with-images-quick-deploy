# Azure Developer CLI (azd) Quick Deploy for Semantic Search with Images

This repository was bootstratpped using the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview) (azd) Bicep starter.


## What's in the Repository

### `/src`: Application code

This solution includes two applications:

- `/src/api`
    - An API hosted as an Azure Function exposing three HTTP-triggered endpoints:
        - `SearchByImageStream`
        - `SearchByImageUrl`
        - `SearchByText`
    - Will be packaged and deployed as part of the `azd up` command flow.
- `/src/migration-tool`
    - A .NET console application that clones the schema and data from a source Azure AI Search index to a target Azure AI Search index in the new deployment.
    - Builds and runs as part of a *post-provisioning* hook in the `azd up` command flow. It is *not* deployed to an Azure application host but runs on the system executing the `azd up` command.
    - For large data sets, this tool may take up to two hours to run.

### `/infra`: Infrastructure-as-code (IaC) Bicep files

[Bicep](https://aka.ms/bicep) files define the required resources and configuration needed to get your application up and running. This solution will create:

- A host for the API application code
    - Azure Function App
    - Azure App Service Plan (used by the Azure Function App)
    - Azure Storage account (used by the Azure Function App)
    - Monitoring components
        - Azure Log Analytics workspace
        - Azure Application Insights
        - Monitoring dashboard
- Azure AI Search for searching images 
- Azure AI Vision (Computer Vision) for multimodal embeddings API access

### `/.devcontainer`: Dev Container configuration

- A [dev container](https://containers.dev) configuration file under the `.devcontainer` directory that installs infrastructure tooling by default. This can be readily used to create cloud-hosted developer environments such as [GitHub Codespaces](https://aka.ms/codespaces).

## Deploy up to Azure

### Step 1: Authenticate to your environment

```sh
azd auth login
```

When run without any arguments, logs in interactively using a browser. To log in using a device code, pass `--use-device-code`. If you have access to multiple tenants, you may need to specify `--tenant-id` if you are unable to find the subscription using the default tenant. To log in as a service principal, pass `--client-id` and `--tenant-id` as well as one of: `--client-secret`, `--client-certificate`, or `--federated-credential-provider`.

### Step 2: Package, provision, and deploy up to Azure

```sh
azd up
```

The `azd up` command runs the application code packaging (`azd package`), end-to-end infrastructure provisioning (`azd provision`), post-provisioning hook to run the migration tool, and application code deployment (`azd deploy`) flow. Upon successful completion of the steps, the function API service endpoint will be listed and can be used to verify your application is up-and-running!

#### Location constraints
The selected location needs to have quota to deploy an Azure AI Vision resource with access to multimodal embeddings. US regions limited to **East US**, **West US**, and **West US 2** at the time of last update, but check [region availability](https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/overview-image-analysis?tabs=4-0#region-availability).

#### Source search key
When prompted, enter the search key provided in order for the migration tool to connect to the source search index to clone the index schema and data.

### Optional tear down

If you no longer need the environment in Azure, run `azd down` to delete all resources created by the solution. This step may be helpful if there were errors in deployment; however, you likely will want the resources to remain deployed to host the solution. All resources should be contained within a single resource group for easy future cleanup if the AZD environment is lost.
