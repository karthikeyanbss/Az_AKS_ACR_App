targetScope = 'resourceGroup'

@description('Azure region for AKS and ACR resources.')
param location string = resourceGroup().location

@description('AKS cluster name.')
param aksClusterName string = 'aks-minimal-test'

@description('Azure Container Registry name. Must be globally unique, 5-50 lowercase alphanumeric characters.')
param acrName string

@description('DNS prefix for the AKS API server endpoint.')
param dnsPrefix string = 'aksminimaltest'

@description('VM size for the AKS system node pool.')
param systemNodeVmSize string = 'Standard_D2s_v3'

@description('Node count for the AKS system node pool.')
@minValue(1)
param systemNodeCount int = 1

@description('VM size for the AKS user node pool.')
param userNodeVmSize string = 'Standard_D4s_v3'

@description('Node count for the AKS user node pool.')
@minValue(1)
param userNodeCount int = 1

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-03-01' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: dnsPrefix
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: systemNodeCount
        vmSize: systemNodeVmSize
        mode: 'System'
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
      }
    ]
    networkProfile: {
      networkPlugin: 'kubenet'
      loadBalancerSku: 'standard'
    }
  }
}

resource aksUserPool 'Microsoft.ContainerService/managedClusters/agentPools@2024-03-01' = {
  parent: aks
  name: 'usernodepool'
  properties: {
    count: userNodeCount
    vmSize: userNodeVmSize
    mode: 'User'
    osType: 'Linux'
    type: 'VirtualMachineScaleSets'
  }
}

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(acr.id, aks.id, 'AcrPull')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: aks.properties.identityProfile.kubeletIdentity.objectId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    aksUserPool
  ]
}

output deployedResourceGroup string = resourceGroup().name
output deployedAksName string = aks.name
output deployedAcrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
