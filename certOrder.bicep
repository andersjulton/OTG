// Bicep file for the deployment of certificates

param certOrderName string
param location string = 'global'
param autoRenew bool
param distinguishedName string
param productType string
param certName string
param keyVaultId string
param keyVaultSecretName string

param makeCertOrder bool = false
param makeCert bool = false

resource certOrder 'Microsoft.CertificateRegistration/certificateOrders@2021-02-01' = if (makeCertOrder) {
  name: certOrderName
  location: location
  properties: {
    autoRenew: autoRenew
    distinguishedName: distinguishedName
    productType: productType
  }
}

resource cert 'Microsoft.CertificateRegistration/certificateOrders/certificates@2021-02-01' = if (makeCert) {
  name: certName
  location: location
  parent: certOrder
  properties: {
    keyVaultId: keyVaultId
    keyVaultSecretName: keyVaultSecretName
  }
}
