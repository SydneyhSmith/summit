metadata name = 'Azure Infrastructure Summit'
metadata description = 'Subscription-scoped entry point — creates the resource group and delegates to the webapp module'

targetScope = 'subscription'

// ── Parameters ───────────────────────────────────────────────────────────────

@description('Azure region for all resources.')
param location string = 'canadacentral'

@description('Name of the resource group to create.')
param resourceGroupName string = 'rg-summit'

// ── Resource Group ────────────────────────────────────────────────────────────

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    project: 'azure-infrastructure-summit'
    environment: 'production'
  }
}

// ── Web App Module ────────────────────────────────────────────────────────────

module webapp 'modules/webapp.bicep' = {
  name: 'summit-webapp'
  scope: rg
  params: {
    location: location
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output webAppName string = webapp.outputs.webAppName
output webAppUrl string = webapp.outputs.webAppUrl
