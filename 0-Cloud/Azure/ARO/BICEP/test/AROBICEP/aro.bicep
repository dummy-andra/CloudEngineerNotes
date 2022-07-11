param clusterName string = 'aro-cluster'
param podCidr string = '10.128.0.0/14'
param serviceCidr string = '172.30.0.0/16'
param apiServerVisibility string = 'Public'
param ingressVisibility string = 'Public'
param masterVmSku string = 'Standard_D8s_v3'

param masterSubnetId string
param workerSubnetId string
param clientId string
param clientSecret string
param pullSecret string

param basePrefix string = 'bicep-node'
param clusterResourceGroupName string = 'aro-${basePrefix}'

//  The Id of the managed Resource Group that will be created. This must be unique and must not already exist
//"resourceGroupId": "[concat('/subscriptions/', subscription().subscriptionId,'/resourceGroups/aro-', parameters('domain'))]",
var clusterResourceGroupId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${clusterResourceGroupName}'


@description('Domain of cluster.')
//  [Required for template deployment]
//  Create default vaule if not supplied, simiarl to CLI
param clusterDomain string = '${basePrefix}.${resourceGroup().location}.aroapp.io'


var ingressSpec = [
  {
    name: 'default'
    visibility: ingressVisibility
  }
]

var workerSpec = {
  name: 'worker'
  VmSize: 'Standard_D4s_v3'
  diskSizeGB: 128
  count: 3
}

resource cluster 'Microsoft.RedHatOpenShift/openShiftClusters@2020-04-30' = {
  name: clusterName
  location: resourceGroup().location
  properties: {
    clusterProfile: {
      domain: clusterDomain
      //resourceGroupId: resourceGroup().id
      resourceGroupId: clusterResourceGroupId
      pullSecret: pullSecret
    }
    apiserverProfile: {
      visibility: apiServerVisibility
    }
    ingressProfiles: [for instance in ingressSpec: {
      name: instance.name
      visibility: instance.visibility
    }]
    masterProfile: {
      vmSize: masterVmSku
      subnetId: masterSubnetId
    }
    workerProfiles: [
      {
        name: workerSpec.name
        vmSize: workerSpec.VmSize
        diskSizeGB: workerSpec.diskSizeGB
        subnetId: workerSubnetId
        count: workerSpec.count
      }
    ]
    networkProfile: {
      podCidr:podCidr
      serviceCidr: serviceCidr
    }
    servicePrincipalProfile: {
      clientId: clientId
      clientSecret: clientSecret
    }
  }
}

output consoleUrl string = cluster.properties.consoleProfile.url
output apiUrl string = cluster.properties.apiserverProfile.url
