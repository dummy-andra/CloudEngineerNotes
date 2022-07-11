var rpServicePrincipalObjectId = 'xxx'  

resource ncrole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: 'xxx'
}
resource roleassignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id)
  properties: {
    // principalId: clientObjectId
    principalId: rpServicePrincipalObjectId
    roleDefinitionId: ncrole.id
    principalType: 'ServicePrincipal'
  }
}

