param name string
param location string
param tags object
param httpsOnly bool
param serverFarmId string = ''
// Format
// "/subscriptions/{subscriptionID}/resourceGroups/{groupName}/providers/Microsoft.Web/serverfarms/{appServicePlanName}".
param alwaysOn bool
param appSettings array
param connectionStrings array
// Format
// connectionStrings: [
//   {
//     connectionString: 'string'
//     name: 'string'
//     type: 'string'
//   }
// ]
param http20Enabled bool
param remoteDebuggingEnabled bool
param ipSecurityRestrictions array
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
param use32BitWorkerProcess bool
param webSocketsEnabled bool
param slotName string
param deploymentName string
// param deploymentKind string

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    httpsOnly: httpsOnly
    serverFarmId: serverFarmId
    siteConfig: {
      alwaysOn: alwaysOn
      appSettings: appSettings
      connectionStrings: connectionStrings
      http20Enabled: http20Enabled
      remoteDebuggingEnabled: remoteDebuggingEnabled
      ipSecurityRestrictions: ipSecurityRestrictions
      use32BitWorkerProcess: use32BitWorkerProcess
      webSocketsEnabled: webSocketsEnabled
    }
  }
  resource slot 'slots@2021-02-01' = {
    name: slotName
    location: location
    // kind: deploymentKind
    properties: {
    }
    resource deployment 'deployments@2021-02-01' = {
      name: deploymentName
    }
  }
}
