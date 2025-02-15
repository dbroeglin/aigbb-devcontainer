metadata name = 'ai-gbb-devcontainer'
metadata description = 'Deploys the infrastructure for AI GBB DevContainer'
metadata author = 'Dominique Broeglin <dominique.broeglin@microsoft.com>'

/* -------------------------------------------------------------------------- */
/*                                 PARAMETERS                                 */
/* -------------------------------------------------------------------------- */

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@description('Principal ID of the user runing the deployment')
param azurePrincipalId string

@description('Extra tags to be applied to provisioned resources')
param extraTags object = {}

@description('Location for all resources')
param location string = resourceGroup().location

@description('If true, deploys an Azure Search instance')
param hasAzureAISearch bool = false

@description('Optional. Defines the SKU of an Azure AI Search Service, which determines price tier and capacity limits.')
@allowed([
  'basic'
  'free'
  'standard'
  'standard2'
  'standard3'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
param aiSearchSkuName string = 'basic'

/* ---------------------------- Shared Resources ---------------------------- */

@maxLength(63)
@description('Name of the log analytics workspace to deploy. If not specified, a name will be generated. The maximum length is 63 characters.')
param logAnalyticsWorkspaceName string = ''

@maxLength(255)
@description('Name of the application insights to deploy. If not specified, a name will be generated. The maximum length is 255 characters.')
param applicationInsightsName string = ''

/* -------------------------------------------------------------------------- */
/*                                  VARIABLES                                 */
/* -------------------------------------------------------------------------- */

@description('Abbreviations to be used in resource names loaded from a JSON file')
var abbreviations = loadJsonContent('./abbreviations.json')

@description('Generate a unique token to make global resource names unique')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

@description('Name of the environment with only alphanumeric characters. Used for resource names that require alphanumeric characters only')
var alphaNumericEnvironmentName = replace(replace(environmentName, '-', ''), ' ', '')

@description('Tags to be applied to all provisioned resources')
var tags = union(
  {
    'azd-env-name': environmentName
    solution: 'ai-gbb-devcontainer'
  },
  extraTags
)

@description('Azure OpenAI API Version')
var azureOpenAIApiVersion = '2024-12-01-preview'

// *** Important: Order matters to the Output variables
@description('Model deployment configurations')
var deployments = [
  {
    name: 'gpt-4o-2024-11-20'
    sku: {
      name: 'GlobalStandard'
      capacity: 50
    }
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-11-20'
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
  {
    name: 'gpt-4o-mini-2024-07-18'
    sku: {
      name: 'GlobalStandard'
      capacity: 50
    }
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
  // {
  //   name: 'o3-mini-2025-01-31'
  //   sku: {
  //     name: 'GlobalStandard'
  //     capacity: 50
  //   }
  //   model: {
  //     format: 'OpenAI'
  //     name: 'o3-mini'
  //     version: '2025-01-31'
  //   }
  //   versionUpgradeOption: 'OnceCurrentVersionExpired'
  // }
]

/* --------------------- Globally Unique Resource Names --------------------- */

/****************************** AI GBB Tip ***********************************
 * Define here all the globally unique resources names. They should
 * always include resourceToken to ensure uniqueness.
 ******************************************************************************/

/* ----------------------------- Resource Names ----------------------------- */

/****************************** AI GBB Tip ***********************************
 * Define here all the all other resource names. Use
 * variable alphaNumericEnvironmentName for names that should not
 * contain non-alphanumeric characters. We use the take() function
 * to shorten the names to the maximum length allowed by Azure.
 ******************************************************************************/

var _aiHubName = take('${abbreviations.aiPortalHub}${environmentName}', 260)
var _aiProjectName = take('${abbreviations.aiPortalProject}${environmentName}', 260)
var _aiSearchServiceName = take('${abbreviations.searchSearchServices}${environmentName}', 260)
var _applicationInsightsName = !empty(applicationInsightsName)
  ? applicationInsightsName
  : take('${abbreviations.insightsComponents}${environmentName}', 255)
var _azureOpenAiName = take(
  '${abbreviations.cognitiveServicesOpenAI}${alphaNumericEnvironmentName}${resourceToken}',
  63
)
var _keyVaultName = take('${abbreviations.keyVaultVaults}${alphaNumericEnvironmentName}-${resourceToken}', 24)
var _logAnalyticsWorkspaceName = !empty(logAnalyticsWorkspaceName)
  ? logAnalyticsWorkspaceName
  : take('${abbreviations.operationalInsightsWorkspaces}${environmentName}', 63)
var _storageAccountName = take(
  '${abbreviations.storageStorageAccounts}${alphaNumericEnvironmentName}${resourceToken}',
  24
)

/* -------------------------------------------------------------------------- */
/*                                  RESOURCES                                 */
/* -------------------------------------------------------------------------- */

/****************************** AI GBB Tip ***********************************
 * Favor using Azure Verified Modules over custom Bicep modules
 * see https://aka.ms/bicep/aztip/azure-verified-modules for more
 * information on Azure Verified Modules
 ******************************************************************************/

module hub 'modules/ai/hub.bicep' = {
  name: 'hub'
  params: {
    location: location
    tags: tags
    name: _aiHubName
    displayName: _aiHubName
    keyVaultId: keyVault.outputs.resourceId
    storageAccountId: storageAccount.outputs.resourceId
    applicationInsightsId: appInsightsComponent.outputs.resourceId
    openAiName: azureOpenAi.outputs.name
    openAiConnectionName: 'aoai-connection'
    openAiContentSafetyConnectionName: 'aoai-content-safety-connection'
    aiSearchName: hasAzureAISearch ? aiSearchService.outputs.name : ''
    aiSearchConnectionName: 'search-service-connection'
  }
}

module project 'modules/ai/project.bicep' = {
  name: 'project'
  params: {
    location: location
    tags: tags
    name: _aiProjectName
    displayName: _aiProjectName
    hubName: hub.outputs.name
  }
}

module azureOpenAi 'modules/ai/cognitiveservices.bicep' = {
  name: 'cognitiveServices'
  params: {
    location: location
    tags: tags
    name: _azureOpenAiName
    kind: 'AIServices'
    customSubDomainName: _azureOpenAiName
    deployments: deployments
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Cognitive Services OpenAI Contributor'
        principalId: azurePrincipalId
      }
    ]
  }
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.15.0' = {
  name: 'storageAccount'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    name: _storageAccountName
    kind: 'StorageV2'
    blobServices: {
      corsRules: [
        {
          allowedOrigins: [
            'https://mlworkspace.azure.ai'
            'https://ml.azure.com'
            'https://*.ml.azure.com'
            'https://ai.azure.com'
            'https://*.ai.azure.com'
            'https://mlworkspacecanary.azure.ai'
            'https://mlworkspace.azureml-test.net'
          ]
          allowedMethods: [
            'GET'
            'HEAD'
            'POST'
            'PUT'
            'DELETE'
            'OPTIONS'
            'PATCH'
          ]
          maxAgeInSeconds: 1800
          exposedHeaders: [
            '*'
          ]
          allowedHeaders: [
            '*'
          ]
        }
      ]
      containers: [
        {
          name: 'default'
          roleAssignments: [
            {
              roleDefinitionIdOrName: 'Storage Blob Data Contributor'
              principalId: azurePrincipalId
            }
          ]
        }
      ]
      deleteRetentionPolicy: {
        allowPermanentDelete: false
        enabled: false
      }
      shareDeleteRetentionPolicy: {
        enabled: true
        days: 7
      }
    }
  }
}

module aiSearchService 'br/public:avm/res/search/search-service:0.8.2' = if (hasAzureAISearch) {
  name: _aiSearchServiceName
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    name: _aiSearchServiceName
    sku: aiSearchSkuName
  }
}

/* ---------------------------- Observability  ------------------------------ */

module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.9.1' = {
  name: 'workspaceDeployment'
  params: {
    name: _logAnalyticsWorkspaceName
    location: location
    tags: tags
    dataRetention: 30
  }
}

module appInsightsComponent 'br/public:avm/res/insights/component:0.4.2' = {
  name: _applicationInsightsName
  params: {
    name: _applicationInsightsName
    location: location
    workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
  }
}

/* ------------------------ Common App Resources  -------------------------- */

module keyVault 'br/public:avm/res/key-vault/vault:0.11.0' = {
  name: 'keyVault'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    name: _keyVaultName
    enableRbacAuthorization: true
    enablePurgeProtection: false // Set to true to if you deploy in production and want to protect against accidental deletion
    roleAssignments: [
      {
        principalId: azurePrincipalId
        roleDefinitionIdOrName: 'Key Vault Administrator'
      }
    ]
  }
}

/* -------------------------------------------------------------------------- */
/*                                   OUTPUTS                                  */
/* -------------------------------------------------------------------------- */

/****************************** AI GBB Tip ***********************************
 * Outputs are automatically saved in the local azd environment
 * To see these outputs, run `azd env get-values`,  or
 * `azd env get-values --output json` for json output.
 * Generate your own `.env` file: `azd env get-values > .env` (not recommended)
 ******************************************************************************/

@description('Principal ID of the user runing the deployment')
output AZURE_PRINCIPAL_ID string = azurePrincipalId

/* --------------------------- Azure AI Foundry --------------------------- */

@description('Azure AI Project connection string')
output AZURE_AI_PROJECT_CONNECTION_STRING string = project.outputs.connectionString

@description('Azure AI Search endpoint')
output AZURE_AI_SEARCH_ENDPOINT string = 'https://${aiSearchService.name}.search.windows.net'

/* ------------------------------- Models --------------------------------- */

@description('Azure OpenAI endpoint')
output AZURE_OPENAI_ENDPOINT string = azureOpenAi.outputs.endpoint

@description('Azure OpenAI API Version')
output AZURE_OPENAI_API_VERSION string = azureOpenAIApiVersion

@description('Azure OpenAI Model Deployment Name - GPT-4O')
output AZURE_OPENAI_GPT4O_DEPLOYMENT_NAME string = deployments[0].name

@description('Azure OpenAI Model Deployment Name - GPT-4O Mini')
output AZURE_OPENAI_GPT4O_MINI_DEPLOYMENT_NAME string = deployments[1].name

//@description('Azure OpenAI Model Deployment Name - O3 Mini')
//output AZURE_OPENAI_O3_MINI_DEPLOYMENT_NAME string = deployments[2].name

/* --------------------------- Observability ------------------------------ */

@description('Application Insights name')
output AZURE_APPLICATION_INSIGHTS_NAME string = appInsightsComponent.outputs.name

@description('Log Analytics Workspace name')
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = logAnalyticsWorkspace.outputs.name

@description('Application Insights connection string')
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsightsComponent.outputs.connectionString
