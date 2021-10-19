@description('Application name')
param appName string

@description('Database name')
param databaseName string = toLower('${appName}Db')

@description('Location for the resources')
param location string = resourceGroup().location

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' = {
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

resource cosmosDbAccount_sqlDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  parent: cosmosDbAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource cosmosDbAccount_00000000_0000_0000_0000_000000000001 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-06-15' = {
  parent: cosmosDbAccount
  name: '00000000_0000_0000_0000_000000000001'
  properties: {
    roleName: 'Cosmos DB Built-in Data Reader'
    type: 0
    assignableScopes: [
      cosmosDbAccount.id
    ]
    permissions: [
      {
        dataActions: [
          'Microsoft.DocumentDB/databaseAccounts/readMetadata'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/executeQuery'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/readChangeFeed'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/read'
        ]
        notDataActions: []
      }
    ]
  }
}

resource cosmosDbAccount_00000000_0000_0000_0000_000000000002 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-06-15' = {
  parent: cosmosDbAccount
  name: '00000000_0000_0000_0000_000000000002'
  properties: {
    roleName: 'Cosmos DB Built-in Data Contributor'
    type: 0
    assignableScopes: [
      cosmosDbAccount.id
    ]
    permissions: [
      {
        dataActions: [
          'Microsoft.DocumentDB/databaseAccounts/readMetadata'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
        ]
        notDataActions: []
      }
    ]
  }
}

resource cosmosDbAccount_Container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  parent: cosmosDbAccount_sqlDb
  name: 'Contacts'
  properties: {
    resource: {
      id: 'Contacts'
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/partitionKey'
        ]
        kind: 'Hash'
      }
      uniqueKeyPolicy: {
        uniqueKeys: []
      }
      conflictResolutionPolicy: {
        mode: 'LastWriterWins'
        conflictResolutionPath: '/_ts'
      }
    }
  }
  dependsOn: [
    cosmosDbAccount_sqlDb
  ]
}

resource cosmosDbAccount_Container_default 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/throughputSettings@2021-06-15' = {
  parent: cosmosDbAccount_Container
  name: 'default'
  properties: {
    resource: {
      throughput: 400
    }
  }
  dependsOn: [
    cosmosDbAccount_Container
    cosmosDbAccount_sqlDb
  ]
}
