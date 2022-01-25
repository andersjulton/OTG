param name string
param location string
param kind string
param tags object
param Application_Type string
param SamplingPercentage int 
param RetentionInDays int


resource appInsightComponents 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: kind
  tags: tags
  properties: {
    Application_Type: Application_Type
    SamplingPercentage: SamplingPercentage
    RetentionInDays: RetentionInDays
  }
}
