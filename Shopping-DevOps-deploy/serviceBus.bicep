param serviceBusName string
param location string
param serviceBusTags object
param serviceBusSkuCapacity int
@allowed([
  'Basic'
  'Premium'
  'Standard'
])
param serviceBusSkuName string

param topicName string
param autoDeleteOnIdle string
param defaultMessageTimeToLive string
param duplicateDetectionHistoryTimeWindow string
param enableBatchedOperations bool
param enableExpress bool
param enablePartitioning bool
param maxMessageSizeInKilobytes int
param maxSizeInMegabytes int
param requiresDuplicateDetection bool
@allowed([
  'Active'
  'Creating'
  'Deleting'
  'Disabled'
  'ReceiveDisabled'
  'Renaming'
  'Restoring'
  'SendDisabled'
  'Unknown'
])
param status string
param supportOrdering bool

param authorizationRuleName string
param rights array

resource serviceBusNameSpace 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: serviceBusName
  location: location
  tags: serviceBusTags
  sku: {
    capacity: serviceBusSkuCapacity
    name: serviceBusSkuName
    tier: serviceBusSkuName
  }
  resource topic 'topics@2021-06-01-preview' = {
    name: topicName
    properties: {
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
    }
    resource authorizationRule 'authorizationRules@2021-06-01-preview' = {
      name: authorizationRuleName
      properties: {
        rights: rights
      }
    }
  }
}
