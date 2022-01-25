param name string
param location string
param tags object
param sku string
// param kind string
param hyperV bool
param workerCount int

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
    capacity: workerCount
  }
  // kind: kind
  properties: { 
    hyperV: hyperV
    maximumElasticWorkerCount: workerCount
  }
}
