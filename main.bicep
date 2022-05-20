param apimName string
param appInsName string
param location string = resourceGroup().location
param workspaceName string
param publicIpName string
param subnetName string

resource subnetRef 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing{
  name: subnetName
}

resource pubIP  'Microsoft.Network/publicIPAddresses@2021-08-01' existing = {
  name: publicIpName
}


@description('Pricing tier of this API Management service')
@allowed([
  'Developer'
  'Standard'
  'Premium'
])
param sku string = 'Developer'

@description('The instance size of this API Management service.')
@allowed([
  1
  2
])
param skuCount int = 1

var tagValues = {
    ApplicationName: 'Nombre de la aplicación, modulo o canal que está afectando'
    Approver: 'Andres Iturralde'
    Creator: 'Andres Iturralde'
    BusinessUnit: 'CE'
    BudgetAmount: '1000'
    Env: 'Dev'
    Owner: 'Andres Iturralde'
    StartDate: '16052022'
    EndDate: 'N/A'
    Excepciones: 'N/A'
}

//Creating APIM
resource apim 'Microsoft.ApiManagement/service@2021-12-01-preview' = {
  name: apimName
  location: location
  sku:{
    capacity: skuCount
    name: sku
  }
  properties:{
    
    virtualNetworkType: 'Internal'
    
    publicIpAddressId: pubIP.id
    virtualNetworkConfiguration: {
      subnetResourceId: subnetRef.id
    }

    publisherEmail: 'andres@iturralde.com'
    publisherName: 'ANDRESI'    
  }  
  tags: tagValues
}

// Create a workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: workspaceName
  location: location
  tags: tagValues
}

// Create an App Insights resources connected to the workspace
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsName
  location: location
  kind: 'web'
  tags: tagValues
  properties:{
    Application_Type:'web'
    WorkspaceResourceId: workspace.id
  }
}

resource namedValueAppInsightsKey 'Microsoft.ApiManagement/service/namedValues@2021-12-01-preview' = {
  parent: apim
  name: 'instrumentationKey'
  properties: {
    tags: []
    secret: false
    displayName: 'instrumentationKey'
    value: appInsights.properties.InstrumentationKey
  }
}

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2021-12-01-preview' = {
  parent: apim
  name: 'apimlogger'
  properties:{
    resourceId: appInsights.id
    description: 'Application Insights for APIM'
    loggerType: 'applicationInsights'
    credentials:{
      instrumentationKey: appInsights.properties.InstrumentationKey
    }
  }
}

//Adding APIM policies
resource apimPolicy 'Microsoft.ApiManagement/service/policies@2021-12-01-preview' = {
  parent: apim
  name: 'policy'
  properties:{
    value: loadTextContent('./policies.xml')
    format: 'rawxml'
  }
}
