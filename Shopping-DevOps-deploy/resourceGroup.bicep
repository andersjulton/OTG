param rgName string
param location string 
param tags object
param managedBy string
param properties object


targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
  tags: tags
  managedBy: managedBy
  properties: properties
}
