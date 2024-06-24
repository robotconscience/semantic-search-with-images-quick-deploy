targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions.
// Add the following to main.parameters.json to provide values:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param resourceGroupName string = ''

@minLength(1)
@description('Query key for read-only access to the source AI Search resource')
@secure()
param sourceSearchKey string
@minLength(1)
@description('Name of the source AI Search resource')
param sourceSearchName string
@minLength(1)
@description('Name of the source AI Search index to clone')
param sourceSearchIndexName string

// To help with post-provisioning access to secrets, grant the current
// principal get/list secrets permissions so that we don't expose keys.
@description('Principal ID of the user running the azd up command (for Key Vault access)')
param currentPrincipalId string = ''

// The secret name in Key Vault to store the source AI Search key
var sourceSearchKeySecretName = 'source-ai-search-key'

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// AI Vision (Computer Vision) resource for multimodal embeddings

module vision 'core/ai/cognitiveservices.bicep' = {
  name: 'ai-vision'
  scope: rg
  params: {
    name: 'cv-${resourceToken}'
    location: location
    tags: tags
    kind: 'ComputerVision'
    sku: {
      name: 'S1'
    }
  }
}

// AI Search

module search './core/search/search-services.bicep' = {
  name: 'search'
  scope: rg
  params: {
    name: '${abbrs.searchSearchServices}${resourceToken}'
    location: location
    tags: tags
  }
}

// Key Vault

module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: currentPrincipalId // Grants the current user access to KV secrets
  }
}

// Key Vault Secret for query key

module keyVaultSecret './core/security/keyvault-secret.bicep' = {
  scope: rg
  name: 'keyvault-secret'
  params: {
    keyVaultName: keyVault.outputs.name
    name: sourceSearchKeySecretName
    secretValue: sourceSearchKey
  }
}

// Storage Account (for Function App)

module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
  }
}

// Monitoring (for Function App)

module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: '${abbrs.portalDashboards}${resourceToken}'
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
  }
}

// App Service Plan (to host the Function App)

module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'P1v3'
      tier: 'PremiumV3'
    }
  }
}

// Application backend API (Function App)
module api './app/api.bicep' = {
  name: 'api'
  scope: rg
  dependsOn: [
    vision
    search
  ]
  params: {
    name: '${abbrs.webSitesFunctions}api-${resourceToken}'
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    storageAccountName: storage.outputs.name
    visionName: vision.outputs.name
    searchServiceName: search.outputs.name
  }
}

// Add outputs from the deployment here, if needed.
//
// This allows the outputs to be referenced by other bicep deployments in the deployment pipeline,
// or by the local machine as a way to reference created resources in Azure for local development.
// Secrets should not be added here.
//
// Outputs are automatically saved in the local azd environment .env file.
// To see these outputs, run `azd env get-values`,  or `azd env get-values --output json` for json output.
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name
output SOURCE_AI_SEARCH_KEY_SECRET_NAME string = sourceSearchKeySecretName
output SOURCE_AI_SEARCH_ENDPOINT string = 'https://${sourceSearchName}.search.windows.net'
output SOURCE_AI_SEARCH_INDEX_NAME string = sourceSearchIndexName
output TARGET_AI_SEARCH_ENDPOINT string = search.outputs.endpoint
output TARGET_AI_SEARCH_NAME string = search.outputs.name
output KEYVAULT_NAME string = keyVault.outputs.name
