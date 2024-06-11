param name string
param location string = resourceGroup().location
param tags object = {}

param applicationInsightsName string = ''
param appServicePlanId string
param visionName string
param searchServiceName string
param keyVaultName string
param serviceName string = 'api'
param storageAccountName string

// Pull exiting resources to access keys

resource existingVisionService 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: visionName
}

resource existingSearchService 'Microsoft.Search/searchServices@2023-11-01' existing = {
  name: searchServiceName
}

module api '../core/host/functions.bicep' = {
  name: '${serviceName}-functions-dotnet-isolated-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    corsSupportCredentials: true
    allowedOrigins: [
      'https://image-search-mvp-git-main-the-met.vercel.app'
      'https://image-search-mvp.vercel.app'
      'https://staging-and-preview-web-git-in-gallery-image-search-the-met.vercel.app'
      'http://localhost:3000'
    ]
    appSettings: {
      AiVisionOptions__Key: existingVisionService.listKeys().key1
      AiVisionOptions__Endpoint: existingVisionService.properties.endpoint
      AiVisionOptions__MultimodalEmbeddingsApiVersion: '2024-02-01'
      AiVisionOptions__MultimodalEmbeddingsModelVersion: '2023-04-15'
      AiSearchOptions__Key: existingSearchService.listAdminKeys().primaryKey
      AiSearchOptions__Endpoint: 'https://${existingSearchService.name}.search.windows.net/'
      AiSearchOptions__IndexName: 'semantic-search-images-v'
      AiSearchOptions__IndexImageVectorsFieldName: 'VectorizedImage'
      AiSearchOptions__TopNCount: 3
    }
    alwaysOn: false
    applicationInsightsName: applicationInsightsName
    appServicePlanId: appServicePlanId
    keyVaultName: keyVaultName
    runtimeName: 'dotnet-isolated'
    runtimeVersion: '8.0'
    storageAccountName: storageAccountName
    scmDoBuildDuringDeployment: false
  }
}

output FUNC_API_IDENTITY_PRINCIPAL_ID string = api.outputs.identityPrincipalId
output FUNC_API_NAME string = api.outputs.name
output FUNC_API_URI string = api.outputs.uri
