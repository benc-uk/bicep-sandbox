param suffix string
param location string 

param netVnet string
param netSubnet string
param netSubnetVnodes string = ''
param logsWorkspaceId string

param kube object {
  default: {
    version: '1.19.7'
    nodeSize: 'Standard_DS2_v2'
    nodeCount: 1
    nodeCountMax: 10
  }  
}

resource aks 'Microsoft.ContainerService/managedClusters@2020-12-01' = {
  name: 'aks-${suffix}'
  location: location
  
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    dnsPrefix: 'aks-${suffix}'
    kubernetesVersion: kube.version
    agentPoolProfiles: [
      {
        name: 'default'
        mode: 'System'
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', netVnet, netSubnet)
        vmSize: kube.nodeSize
        enableAutoScaling: true
        count: kube.nodeCount
        minCount: kube.nodeCount
        maxCount: kube.nodeCountMax
      }
    ]
    
    // Enable advanced networking and policy
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
    }

    addonProfiles: {
      // Enable Virtual Nodes
      aciConnectorLinux: {
        enabled: netSubnetVnodes != '' ? true : false
        config: {
          SubnetName: netSubnetVnodes
        }
      }

      // Enable monitoring / Container Insights
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logsWorkspaceId
        }
      }
    }
  }
}

output clusterName string = aks.name
output clusterFQDN string = aks.properties.fqdn
output provisioningState string = aks.properties.provisioningState