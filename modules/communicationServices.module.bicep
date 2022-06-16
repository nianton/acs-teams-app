param name string
param tags object = {}
param dataLocation string

resource acs 'Microsoft.Communication/communicationServices@2020-08-20' = {
  name: name
  location: 'global'
  tags: tags
  properties: {
    dataLocation: dataLocation
  }
} 
