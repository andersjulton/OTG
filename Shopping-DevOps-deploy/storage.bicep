param name string
param location string
param tags object
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_ZRS'
])
param skuName string
@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param kind string
@allowed([
  'None'
  'SystemAssigned'
  'SystemAssigned,UserAssigned'
  'UserAssigned'
])
param identityType string 
var identity = {
  type: identityType
}
@allowed([
  'Cool'
  'Hot'
])
param accessTier string
param allowBlobPublicAccess bool
@allowed([
  'Enabled'
  'Disabled'
])
param largeFileSharesState string
param customDomainName string
param useSubDomainName bool
var customDomain = {
  name: customDomainName
  useSubDomainName: useSubDomainName
}
@allowed([
  'Microsoft.Storage'
  'Microsoft.Keyvault'
])
param keySource string
param keyName string
param keyVaultUri string
param keyVersion string
param blobKeyType string
param fileKeyType string
param queueKeyType string
param tableKeyType string
var keyVaultProperties = {
  keyname: keyName
  keyvaulturi: keyVaultUri
  keyversion: keyVersion
}

param isHnsEnabled bool
@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
])
param minimumTlsVersion string
@allowed([
  'AzureServices'
  'Logging'
  'Metrics'
  'None'
])
param bypass string
@allowed([
  'Allow'
  'Deny'
])
param defaultAction string
param resourceAccessRules array
param ipRules array
param virtualNetworkRules array
param supportHttpsTrafficOnly bool
// Container parameters
param containerName string 
@allowed([
  'Blob'
  'Container'
  'None'
])
param publicAccess string
param defaultEncryptionScope string
param denyEncryptionScopeOverride bool
param immutableStorageWithVersioning bool
param metadata object

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: kind
  identity: identity
  properties: {
    minimumTlsVersion: minimumTlsVersion
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: true
    largeFileSharesState: largeFileSharesState
    customDomain: ((!empty(customDomainName)) ? customDomain : json('null'))
    networkAcls: {
      resourceAccessRules: resourceAccessRules
      bypass: bypass
      virtualNetworkRules: virtualNetworkRules
      ipRules: ipRules
      defaultAction: defaultAction
    }
    supportsHttpsTrafficOnly: supportHttpsTrafficOnly
    encryption: {

      keyvaultproperties: keyVaultProperties
      services: {
        file: {
          keyType: fileKeyType
          enabled: true
        }
        blob: {
          keyType: blobKeyType
          enabled: true
        }
        queue: {
          keyType: queueKeyType
          enabled: true
        }
        table: {
          keyType: tableKeyType
          enabled: true
        }
      }
      keySource: keySource
    }
    isHnsEnabled: isHnsEnabled
    accessTier: accessTier
  }
}

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: '${storageAccount.name}/default/${containerName}'
  properties: {
    immutableStorageWithVersioning: {
      enabled: immutableStorageWithVersioning
    }
    defaultEncryptionScope: defaultEncryptionScope
    denyEncryptionScopeOverride: denyEncryptionScopeOverride
    publicAccess: publicAccess
    metadata: metadata
  }
}
