@description('Application name')
param appName string = 'Rippl'

@description('Database name')
param databaseName string = 'RipplDb'

@description('Location for the resources')
param location string = resourceGroup().location

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-03-15' = {
  name: toLower('cosmos-${appName}')
  location: location
  properties: {
    enableFreeTier: true
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
      }
    ]
  }
}

resource sqlDb 'Microsoft.DocumentDB/databaseAccounts/apis/databases@2016-03-31' = {
  name: '${cosmosDbAccount.name}/${toLower(databaseName)}'
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: 400
    }
  }
}
