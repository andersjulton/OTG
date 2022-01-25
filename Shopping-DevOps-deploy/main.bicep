param subscriptionId string = subscription().subscriptionId
param resourceGroupName string = resourceGroup().name

// Deployment booleans
param deployAppInsight bool = false
param deployAppPlan bool = false
param deployStorage bool = false
param deployServiceBus bool = false
param deployWebApp bool = false

// Parameters for Application Insight
param appInsightName string = ''
param appInsightLocation string = resourceGroupName
param appInsightTags object = {}
param appInsightKind string = 'web'
param Application_Type string = 'web'
param SamplingPercentage int = 100
param RetentionInDays int = 30

// Parameters for Application Service Plan
param appPlanName string = ''
param appPlanLocation string = resourceGroupName
param appPlanTags object = {}
param appPlanSku string = 'B1'
// param appPlanKind string
param hyperV bool = false
param workerCount int = 1

// // Parameters for Storage Account
param storageAccountName string = ''
param storageAccountLocation string = resourceGroupName
param storageAccountTags object = {}
param skuName string = 'Standard_RAGRS'
param storageAccountKind string = 'BlobStorage'
param identityType string = 'SystemAssigned'
param accessTier string = 'Hot'
param allowBlobPublicAccess bool = true
param largeFileSharesState string = 'Disabled'
param customDomainName string = ''
param useSubDomainName bool = false
param keySource string = 'Microsoft.Storage'
param keyName string = ''
param keyVaultUri string = ''
param keyVersion string = ''
param blobKeyType string = 'Account'
param fileKeyType string = 'Account'
param queueKeyType string = 'Account'
param tableKeyType string = 'Account'
param isHnsEnabled bool = false
param minimumTlsVersion string = 'TLS1_1'
param bypass string = 'AzureServices'
param defaultAction string = 'Allow'
param resourceAccessRules array = []
param ipRules array = []
param virtualNetworkRules array = []
param supportHttpsTrafficOnly bool = true

// Parameters for Storage Container
param containerName string = ''
param publicAccess string = 'None'
param defaultEncryptionScope string = '$account-encryption-key'
param denyEncryptionScopeOverride bool = false
param immutableStorageWithVersioning bool = false
param metadata object = {}

// Parameters for Service Bus
param serviceBusName string = ''
param serviceBusLocation string = resourceGroupName
param serviceBusTags object = {}
param serviceBusSkuCapacity int = 1
param serviceBusSkuName string = 'Standard'
// Parameters for Service Bus Topic
param topicName string = ''
param autoDeleteOnIdle string = 'P10675199D'
param defaultMessageTimeToLive string = 'P14D'
param duplicateDetectionHistoryTimeWindow string = 'PT10M'
param enableBatchedOperations bool = true
param enableExpress bool = false
param enablePartitioning bool = false
param maxMessageSizeInKilobytes int = 254
param maxSizeInMegabytes int = 1024
param requiresDuplicateDetection bool = false
param status string = 'Active'
param supportOrdering bool = false
// Parameters for Service Bus Topic Authorization Rules
param authorizationRuleName string = 'RootManageSharedAccessKey'
param rights array = [
  'Listen'
  'Send'
  'Manage'
]

// Parameters for webapp
param webAppName string = ''
param webAppLocation string = resourceGroupName
param webAppTags object = {}
param httpsOnly bool = true
param serverFarmId string = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Web/serverfarms/${appPlanName}'
param alwaysOn bool = true
param appSettings array = []
param connectionStrings array = []
// Format
// connectionStrings: [
//   {
//     connectionString: 'string'
//     name: 'string'
//     type: 'string'
//   }
// ]
param http20Enabled bool = true
param remoteDebuggingEnabled bool = false
param ipSecurityRestrictions array = []
// Format
// ipSecurityRestrictions: [
//   {
//     action: 'string'
//     ipAddress: 'string'
//     name: 'string'
//     priority: int
//     tag: 'string'
//   }
// ]
param use32BitWorkerProcess bool = false
param webSocketsEnabled bool = true
param deployName string = ''
param slotName string = 'staging'

module appInsightComp 'applicationInsightComponents.bicep' = if (deployAppInsight) {
  name: 'deployAppInsight'
  scope: resourceGroup()
  params: {
    name: appInsightName
    location: appInsightLocation
    tags: appInsightTags
    kind: appInsightKind
    Application_Type: Application_Type
    SamplingPercentage: SamplingPercentage
    RetentionInDays: RetentionInDays
  }
}

module appServicePlan 'appServicePlan.bicep' = if (deployAppPlan) {
  name: 'deployAppServicePlan'
  scope: resourceGroup()
  params: {
    name: appPlanName
    location: appPlanLocation
    tags: appPlanTags
    sku: appPlanSku
    hyperV: hyperV
    workerCount: workerCount
  }
}

module storageAccount 'storage.bicep' = if (deployStorage) {
  name: 'deployStorageAccount'
  scope: resourceGroup()
  params: {
    name: storageAccountName
    location: storageAccountLocation
    tags: storageAccountTags
    skuName: skuName
    kind: storageAccountKind
    identityType: identityType
    accessTier: accessTier
    allowBlobPublicAccess: allowBlobPublicAccess
    largeFileSharesState: largeFileSharesState
    customDomainName: customDomainName
    useSubDomainName: useSubDomainName
    keySource: keySource
    keyName: keyName
    keyVaultUri: keyVaultUri
    keyVersion: keyVersion
    isHnsEnabled: isHnsEnabled
    minimumTlsVersion: minimumTlsVersion
    bypass: bypass
    defaultAction: defaultAction
    resourceAccessRules: resourceAccessRules
    ipRules: ipRules
    virtualNetworkRules: virtualNetworkRules
    supportHttpsTrafficOnly: supportHttpsTrafficOnly

    containerName: containerName
    publicAccess: publicAccess
    defaultEncryptionScope: defaultEncryptionScope
    denyEncryptionScopeOverride: denyEncryptionScopeOverride
    immutableStorageWithVersioning: immutableStorageWithVersioning
    metadata: metadata

    blobKeyType: blobKeyType
    fileKeyType: fileKeyType
    queueKeyType: queueKeyType
    tableKeyType: tableKeyType
  }
}

module serviceBus 'serviceBus.bicep' = if (deployServiceBus) {
  name: 'deployServiceBus'
  scope: resourceGroup()
  params: {
    serviceBusName: serviceBusName
    location: serviceBusLocation
    serviceBusTags: serviceBusTags
    serviceBusSkuName: serviceBusSkuName
    serviceBusSkuCapacity: serviceBusSkuCapacity

    topicName: topicName
    autoDeleteOnIdle: autoDeleteOnIdle
    defaultMessageTimeToLive: defaultMessageTimeToLive
    duplicateDetectionHistoryTimeWindow: duplicateDetectionHistoryTimeWindow
    enableBatchedOperations: enableBatchedOperations
    enableExpress: enableExpress
    enablePartitioning: enablePartitioning
    maxMessageSizeInKilobytes: maxMessageSizeInKilobytes
    maxSizeInMegabytes: maxSizeInMegabytes
    requiresDuplicateDetection: requiresDuplicateDetection
    status: status
    supportOrdering: supportOrdering

    authorizationRuleName: authorizationRuleName
    rights: rights
  }
}

module webApp 'webApp.bicep' = if (deployWebApp) {
  name: 'webAppDeploy'
  scope: resourceGroup()
  params: {
    name: webAppName
    location: webAppLocation
    tags: webAppTags
    httpsOnly: httpsOnly
    serverFarmId: serverFarmId
    alwaysOn: alwaysOn
    appSettings: appSettings
    connectionStrings: connectionStrings
    http20Enabled: http20Enabled
    remoteDebuggingEnabled: remoteDebuggingEnabled
    ipSecurityRestrictions: ipSecurityRestrictions
    use32BitWorkerProcess: use32BitWorkerProcess
    webSocketsEnabled: webSocketsEnabled
    deploymentName: deployName
    slotName: slotName
  }
}
