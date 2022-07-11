targetScope = 'subscription'

param clientId string
param clientSecret string
param pullSecret string
param resourceGroupName string
param resourceGroupLocation string


resource aroRg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
}

output resourceGroupId string = aroRg.id



module vnet 'vnet.bicep' = {
  name: 'module-aro-vnet'
  scope: aroRg
}


// module spcontributor 'sprole.bicep' = {
//   name: 'sprole'
//   scope: aroRg
//   params: {
//     clientId: clientId
//   }
// }

// module rpvnetcontributor 'rprole.bicep' = {
//   name: 'rprole'
//   scope: aroRg

// }




module aro 'aro.bicep' = {
  name: 'module-aro-cluster'
  scope: aroRg
  params: {
    masterSubnetId: vnet.outputs.masterSubnetId
    workerSubnetId: vnet.outputs.workerSubnetId
    clientId: clientId
    clientSecret: clientSecret
    pullSecret: pullSecret
  }
}



