metadata name = 'Summit Web App'
metadata description = 'App Service Plan (F1 free, Linux) and Node.js web app for the Summit site'

// ── Parameters ───────────────────────────────────────────────────────────────

@description('Azure region for all resources.')
param location string

// ── Variables ─────────────────────────────────────────────────────────────────

var webAppName = 'summit-${substring(uniqueString(resourceGroup().id), 0, 6)}'

// ── App Service Plan ──────────────────────────────────────────────────────────

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'asp-summit'
  location: location
  sku: {
    name: 'F1'
    tier: 'Free'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// ── Web App ───────────────────────────────────────────────────────────────────

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      alwaysOn: false
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'NODE_ENV'
          value: 'production'
        }
      ]
    }
  }
}

// ── Publishing Credential Policies ────────────────────────────────────────────

resource scmCredPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: webApp
  name: 'scm'
  properties: {
    allow: false
  }
}

resource ftpCredPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: webApp
  name: 'ftp'
  properties: {
    allow: false
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
