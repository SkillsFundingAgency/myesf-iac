param environment string = 'dev'
param location string = resourceGroup().location
param appServicePlanTier string = environment == 'release' ? 'StandardS3' : 'StandardS1'

// We want 2 instances for production, 1 for all other environments
param appServicePlanInstanceCount int = environment == 'release' ? 2 : 1 
param appServicePlanName string = 'pds-${environment}-myesf-asp'
param appServiceName string = 'pds-${environment}-myesf-as'
param kind string = 'app' 

// Reserved instances are billed at a lower rate, but require a 1-year commitment
param reserved bool = false

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanTier
    capacity: appServicePlanInstanceCount
  }
  kind: kind
  properties: {
    reserved: reserved
  }
}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  kind: kind
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v4.8' // Specify .NET 4.8
      // use32BitWorkerProcess: true // Enable 32-bit worker process for compatibility. Todo: check whether we are targetting x64 or not
    }
  }
}

// Deployment Slots (Identical configurations to the main appService)
resource stagingSlot 'Microsoft.Web/sites/slots@2022-03-01' = {
  name: 'staging'
  parent: appService
  location: location
  kind: kind
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: appService.properties.siteConfig 
  }
}

resource prodSlot 'Microsoft.Web/sites/slots@2022-03-01' = {
  name: 'prod'
  parent: appService
  location: location
  kind: kind
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: appService.properties.siteConfig 
  }
}
