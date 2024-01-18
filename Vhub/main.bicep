metadata name = 'Virtual Hubs'
metadata description = '''This module deploys a Virtual Hub.
If you are planning to deploy a Secure Virtual Hub (with an Azure Firewall integrated), please refer to the Azure Firewall module.'''
metadata owner = 'Azure/module-maintainers'

@description('Required. The virtual hub name.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object?

@description('Required. Address-prefix for this VirtualHub.')
param addressPrefix string

@description('Optional. Flag to control transit for VirtualRouter hub.')
param allowBranchToBranchTraffic bool = true

@description('Optional. Resource ID of the Express Route Gateway to link to.')
param expressRouteGatewayId string = ''

@description('Optional. Resource ID of the Point-to-Site VPN Gateway to link to.')
param p2SVpnGatewayId string = ''

@description('Optional. The preferred routing gateway types.')
@allowed([
  'ExpressRoute'
  'None'
  'VpnGateway'
  ''
])
param preferredRoutingGateway string

@description('Optional. VirtualHub route tables.')
param routeTableRoutes array = []

@description('Optional. ID of the Security Partner Provider to link to.')
param securityPartnerProviderId string = ''

@description('Optional. The Security Provider name.')
param securityProviderName string = ''

@allowed([
  'Basic'
  'Standard'
])
@description('Optional. The sku of this VirtualHub.')
param sku string = 'Standard'

@description('Optional. List of all virtual hub route table v2s associated with this VirtualHub.')
param virtualHubRouteTableV2s array = []

@description('Optional. VirtualRouter ASN.')
param virtualRouterAsn int = -1

@description('Optional. VirtualRouter IPs.')
param virtualRouterIps array = []

@description('Required. Resource ID of the virtual WAN to link to.')
param virtualWanId string

@description('Optional. Resource ID of the VPN Gateway to link to.')
param vpnGatewayId string = ''

@description('Name of the VPN Gateway. A VPN Gateway is created inside a virtual hub.')
param vpnGatewayName string

@description('Name of the vpnsite. A vpnsite represents the on-premise vpn device. A public ip address is mandatory for a VPN Site creation.')
param vpnSiteName string

@description('Name of the vpnconnection. A vpn connection is established between a vpnsite and a VPN Gateway.')
param connectionName string

@description('A list of static routes corresponding to the VPN Gateway. These are configured on the VPN Gateway. Mandatory if BGP is disabled.')
param vpnSiteAddressspaceList array = [ '10.10.0.0/24' ]

@description('The public IP address of a VPN Site.')
param vpnSitePublicIPAddress string

@description('The BGP ASN number of a VPN Site. Unused if BGP is disabled.')
param vpnSiteBgpAsn int

@description('The BGP peer IP address of a VPN Site. Unused if BGP is disabled.')
param vpnSiteBgpPeeringAddress string

@description('This needs to be set to true if BGP needs to enabled on the VPN connection.')
param enableBgp bool = false

param Policyname string

param fwname string

param spokenetworkname string

param hubspokename string

/* 
@description('Optional. Route tables to create for the virtual hub.')
param hubRouteTables array = []

@description('Optional. Virtual network connections to create for the virtual hub.')
param hubVirtualNetworkConnections array = [] */

/* @description('Optional. The lock settings of the service.')
param lock lockType */

/* @description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true */
/* 
var enableReferencedModulesTelemetry = false */

/* resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name, location)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
} */

resource virtualHub 'Microsoft.Network/virtualHubs@2022-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressPrefix: addressPrefix
    allowBranchToBranchTraffic: allowBranchToBranchTraffic
    expressRouteGateway: !empty(expressRouteGatewayId) ? {
      id: expressRouteGatewayId
    } : null
    p2SVpnGateway: !empty(p2SVpnGatewayId) ? {
      id: p2SVpnGatewayId
    } : null
    preferredRoutingGateway: !empty(preferredRoutingGateway) ? any(preferredRoutingGateway) : null
    routeTable: !empty(routeTableRoutes) ? {
      routes: routeTableRoutes
    } : null
    securityPartnerProvider: !empty(securityPartnerProviderId) ? {
      id: securityPartnerProviderId
    } : null
    securityProviderName: securityProviderName
    sku: sku
    virtualHubRouteTableV2s: virtualHubRouteTableV2s
    virtualRouterAsn: virtualRouterAsn != -1 ? virtualRouterAsn : null
    virtualRouterIps: !empty(virtualRouterIps) ? virtualRouterIps : null
    virtualWan: {
      id: virtualWanId
    }
    vpnGateway: !empty(vpnGatewayId) ? {
      id: vpnGatewayId
    } : null
  }
}

resource vpnSite 'Microsoft.Network/vpnSites@2021-03-01' = {
  name: vpnSiteName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vpnSiteAddressspaceList
    }
    bgpProperties: (enableBgp ? {
      asn: vpnSiteBgpAsn
      bgpPeeringAddress: vpnSiteBgpPeeringAddress
      peerWeight: 0
    } : null)
    deviceProperties: {
      linkSpeedInMbps: 10
    }
    ipAddress: vpnSitePublicIPAddress
    virtualWan: {
      id: virtualWanId
    }
  }
}

resource vpnGateway 'Microsoft.Network/vpnGateways@2021-03-01' = {
  name: vpnGatewayName
  location: location
  properties: {
    connections: [
      {
        name: connectionName
        properties: {
          connectionBandwidth: 10
          enableBgp: enableBgp
          remoteVpnSite: {
            id: vpnSite.id
          }
        }
      }
    ]
    virtualHub: {
      id: virtualHub.id
    }
    bgpSettings: {
      asn: 65515
    }
  }
}

resource policy 'Microsoft.Network/firewallPolicies@2021-08-01' = {
  name: Policyname
  location: location
  properties: {
    threatIntelMode: 'Alert'
  }
}

resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-08-01' = {
  parent: policy
  name: 'DefaultApplicationRuleCollectionGroup'
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'RC-01'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'Allow-msft'
            sourceAddresses: [
              '*'
            ]
            protocols: [
              {
                port: 80
                protocolType: 'Http'
              }
              {
                port: 443
                protocolType: 'Https'
              }
            ]
            targetFqdns: [
              '*.microsoft.com'
            ]
          }
        ]
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-08-01' = {
  name: fwname
  location: location
  properties: {
    sku: {
      name: 'AZFW_Hub'
      tier: 'Standard'
    }
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    virtualHub: {
      id: virtualHub.id
    }
    firewallPolicy: {
      id: policy.id
    }
  }
}

resource hubVNetconnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2021-08-01' = {
  parent: virtualHub
  name: hubspokename
  dependsOn: [
    firewall
  ]
  properties: {
    remoteVirtualNetwork: {
      id: virtualNetwork.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: false
    enableInternetSecurity: true
    routingConfiguration: {
      associatedRouteTable: {
        id: hubRouteTable.id
      }
      propagatedRouteTables: {
        labels: [
          'VNet'
        ]
        ids: [
          {
            id: hubRouteTable.id
          }
        ]
      }
    }
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: spokenetworkname
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/23'
      ]
    }
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource subnet_Workload_SN 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  parent: virtualNetwork
  name: 'Workload-SN'
  properties: {
    addressPrefix: '10.100.1.0/24'
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource hubRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2021-08-01' = {
  parent: virtualHub
  name: 'RT_VNet'
  properties: {
    routes: [
      {
        name: 'Workload-SNToFirewall'
        destinationType: 'CIDR'
        destinations: [
          '10.0.1.0/24'
        ]
        nextHopType: 'ResourceId'
        nextHop: firewall.id
      }
      {
        name: 'InternetToFirewall'
        destinationType: 'CIDR'
        destinations: [
          '0.0.0.0/0'
        ]
        nextHopType: 'ResourceId'
        nextHop: firewall.id
      }
    ]
    labels: [
      'VNet'
    ]
  }
}

/* resource virtualHub_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${name}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?kind == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot delete or modify the resource or child resources.'
  }
  scope: virtualHub
} */
/* 
module virtualHub_routeTables 'hub-route-table/main.bicep' = [for (routeTable, index) in hubRouteTables: {
  name: '${uniqueString(deployment().name, location)}-routeTable-${index}'
  params: {
    virtualHubName: virtualHub.name
    name: routeTable.name
    labels: contains(routeTable, 'labels') ? routeTable.labels : []
    routes: contains(routeTable, 'routes') ? routeTable.routes : []
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
}] */

/* module virtualHub_hubVirtualNetworkConnections 'hub-virtual-network-connection/main.bicep' = [for (virtualNetworkConnection, index) in hubVirtualNetworkConnections: {
  name: '${uniqueString(deployment().name, location)}-connection-${index}'
  params: {
    virtualHubName: virtualHub.name
    name: virtualNetworkConnection.name
    enableInternetSecurity: contains(virtualNetworkConnection, 'enableInternetSecurity') ? virtualNetworkConnection.enableInternetSecurity : true
    remoteVirtualNetworkId: virtualNetworkConnection.remoteVirtualNetworkId
    routingConfiguration: contains(virtualNetworkConnection, 'routingConfiguration') ? virtualNetworkConnection.routingConfiguration : {}
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
  dependsOn: [
    virtualHub_routeTables
  ]
}] */

@description('The resource group the virtual hub was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The resource ID of the virtual hub.')
output resourceId string = virtualHub.id

@description('The name of the virtual hub.')
output name string = virtualHub.name

@description('The location the resource was deployed into.')
output location string = virtualHub.location

// =============== //
//   Definitions   //
// =============== //

type lockType = {
  @description('Optional. Specify the name of lock.')
  name: string?

  @description('Optional. Specify the type of lock.')
  kind: ('CanNotDelete' | 'ReadOnly' | 'None')?
}?
