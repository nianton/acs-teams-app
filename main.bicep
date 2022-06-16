param naming object
param location string = resourceGroup().location
param tags object
param acsDataLocation string

@description('The throughput for the database to be shared')
@minValue(400)
@maxValue(1000000)
param cosmosDbThroughput int = 1000

var cosmosDbLocations = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
]

var resourceNames = {
  communicationServices: naming.communicationServices.name
  botService: naming.botWebApp.name
  webApp: naming.appService.name
  storageAccount: naming.storageAccount.nameUnique
  keyVault: naming.keyVault.nameUnique
  cosmosDbAccount: naming.cosmosdbAccount.name
  cosmosDbDatabase: replace(naming.cosmosdbAccount.name, '${naming.cosmosdbAccount.slug}-', 'cdb-')
  cosmosDbCollection: 'chatSessions'
}

var secretNames = {
  dataStorageConnectionString: 'dataStorageConnectionString'
  cosmosDbConnectionString: 'cosmosDbConnectionString'
}

module storage 'modules/storage.module.bicep' = {
  name: 'storage-deployment'
  params: {
    location: location
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    name: resourceNames.storageAccount
    tags: tags
  }
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2019-08-01' = {
  name: resourceNames.cosmosDbAccount
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: cosmosDbLocations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
  }
}

resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2019-08-01' = {
  parent: cosmosDbAccount
  name: resourceNames.cosmosDbDatabase
  properties: {
    resource: {
      id: resourceNames.cosmosDbDatabase
    }
    options: {
      throughput: '${cosmosDbThroughput}'
    }
  }
}

resource cosmosDbContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2019-08-01' = {
  parent: cosmosDbDatabase
  name: resourceNames.cosmosDbCollection
  properties: {
    options: { }
    resource: {
      id: resourceNames.cosmosDbCollection
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'Consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/myPathToNotIndex/*'
          }
        ]
      }
    }
  }
}

module webApp 'modules/webApp.module.bicep' = {
  name: 'webApp-deployment'
  params: {
    name: resourceNames.webApp
    location: location
    tags: tags
    skuName: 'P1v3'
    managedIdentity: true
    appSettings: [
      {
        name: 'StorageConnection'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.dataStorageConnectionString})'
      }
      {
        name: 'CosmosDbConnection'
        value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.cosmosDbConnectionString})'
      }
      {
        name: 'CosmosDbName'
        value: resourceNames.cosmosDbDatabase
      }
      {
        name: 'CosmosDbContainerName'
        value: resourceNames.cosmosDbCollection
      }
    ]
  }
  dependsOn: [
    cosmosDbContainer
    storage
  ]
}

module communicationServices 'modules/communicationServices.module.bicep' = {
  name: 'communicationServices-deployment'
  params: {
    name: resourceNames.communicationServices
    dataLocation: acsDataLocation
  }
}

module bot 'modules/botService.module.bicep' = {
  name: 'bot-deployment'
  params: {
    name: resourceNames.botService
    location: location
    displayName: resourceNames.botService
  }
}

module keyVault 'modules/keyvault.module.bicep' = {
  name: 'keyVault-deployment'
  params: {
    name: resourceNames.keyVault
    location: location
    skuName: 'premium'
    tags: tags
    accessPolicies: [
      {
        tenantId: webApp.outputs.identity.tenantId
        objectId: webApp.outputs.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
    secrets: [
      {
        name: secretNames.dataStorageConnectionString
        service: {
          type: 'storageAccount'
          name: storage.outputs.name
          id: storage.outputs.id
          apiVersion: storage.outputs.apiVersion
        }
      }
      {
        name: secretNames.cosmosDbConnectionString
        value: listConnectionStrings(cosmosDbAccount.id, cosmosDbAccount.apiVersion).connectionStrings[0].connectionString
      }
    ]
  }
}

output webApp object = webApp
output storageAccountName string = storage.outputs.name
