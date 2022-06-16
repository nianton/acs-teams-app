param name string
param location string
param tags object = {}
param displayName string

@allowed([
  'F0'
  'S1'
])
param skuName string = 'S1'

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'uai-${name}'
  location: location
}

resource botService 'Microsoft.BotService/botServices@2021-05-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'azurebot'
  sku: {
    name: skuName
  }
  properties: {
    msaAppType: 'UserAssignedMSI'
    msaAppId: userAssignedIdentity.properties.clientId
    msaAppMSIResourceId: userAssignedIdentity.id
    msaAppTenantId: userAssignedIdentity.properties.tenantId
    displayName: displayName
    endpoint: ''
  }
}
