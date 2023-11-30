@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Name of the Image Template to be built by the Azure Image Builder service.')
param name string

@description('Generated. Do not provide a value! This date value is used to generate a unique image template name.')
param baseTime string = utcNow('yyyy-MM-dd-HH-mm-ss')

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Size of the VM to be used to build the image.')
param vmSize string = 'Standard_B4s_v2'

@description('Optional. Image build timeout in minutes. Allowed values: 0-960. 0 means the default 240 minutes.')
@minValue(0)
@maxValue(960)
param buildTimeoutInMinutes int = 0

@description('Required. Name of the User Assigned Identity to be used to deploy Image Templates in Azure Image Builder.')
param userMsiName string

@description('Optional. Resource group of the user assigned identity.')
param userMsiResourceGroup string = resourceGroup().name

@description('Optional. Specifies the size of OS disk.')
param osDiskSizeGB int = 128

@description('''Optional. List of User-Assigned Identities associated to the Build VM for accessing Azure resources such as Key Vaults from your customizer scripts.
Be aware, the user assigned identity specified in the \'userMsiName\' parameter must have the \'Managed Identity Operator\' role assignment on all the user assigned identities
specified in this parameter for Azure Image Builder to be able to associate them to the build VM.
''')
param userAssignedIdentities array = []

@description('''
Optional. Resource ID of an already existing subnet, e.g.: /subscriptions/<subscriptionId>/resourceGroups/<resourceGroupName>/providers/Microsoft.Network/virtualNetworks/<vnetName>/subnets/<subnetName>.
If no value is provided, a new temporary VNET and subnet will be created in the staging resource group and will be deleted along with the remaining temporary resources.
''')
param subnetId string = ''

@description('Optional. Resource ID of Shared Image Gallery to distribute image to, e.g.: /subscriptions/<subscriptionID>/resourceGroups/<SIG resourcegroup>/providers/Microsoft.Compute/galleries/<SIG name>/images/<image definition>.')
param sigImageDefinitionId string = ''

@description('Optional. Version of the Shared Image Gallery Image. Supports the following Version Syntax: Major.Minor.Build (i.e., \'1.1.1\' or \'10.1.2\').')
param sigImageVersion string = ''

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
])
@description('Optional. Storage account type to be used to store the image in the Azure Compute Gallery.')
param storageAccountType string = 'Standard_LRS'

@description('Optional. Exclude the created Azure Compute Gallery image version from the latest.')
param excludeFromLatest bool = false

@description('Optional. List of the regions the image produced by this solution should be stored in the Shared Image Gallery. When left empty, the deployment\'s location will be taken as a default value.')
param imageReplicationRegions array = []

@description('''Optional. Resource ID of the staging resource group in the same subscription and location as the image template that will be used to build the image.
If this field is empty, a resource group with a random name will be created.
If the resource group specified in this field doesn\'t exist, it will be created with the same name.
If the resource group specified exists, it must be empty and in the same region as the image template.
The resource group created will be deleted during template deletion if this field is empty or the resource group specified doesn\'t exist,
but if the resource group specified exists the resources created in the resource group will be deleted during template deletion and the resource group itself will remain.
''')
param stagingResourceGroup string = ''

var imageSource = {
  type: 'PlatformImage'
  publisher: 'microsoftwindowsdesktop'
  offer: 'windows-11'
  sku: 'win11-23h2-avd'
  version: 'latest'
}

var imageReplicationRegionsVar = empty(imageReplicationRegions) ? array(location) : imageReplicationRegions
var distribute = empty(sigImageDefinitionId) ? [] : array(sharedImage)

var sharedImage = {
  type: 'SharedImage'
  galleryImageId: empty(sigImageVersion) ? sigImageDefinitionId : '${sigImageDefinitionId}/versions/${sigImageVersion}'
  excludeFromLatest: excludeFromLatest
  replicationRegions: imageReplicationRegionsVar
  storageAccountType: storageAccountType
  runOutputName: !empty(sigImageDefinitionId) ? '${last(split(sigImageDefinitionId, '/'))}-SharedImage' : 'SharedImage'
  artifactTags: {
    sourceType: imageSource.type
    sourcePublisher: contains(imageSource, 'publisher') ? imageSource.publisher : null
    sourceOffer: contains(imageSource, 'offer') ? imageSource.offer : null
    sourceSku: contains(imageSource, 'sku') ? imageSource.sku : null
    sourceVersion: contains(imageSource, 'version') ? imageSource.version : null
    creationTime: baseTime
  }
}

var vnetConfig = {
  subnetId: subnetId
}

// Image Template
resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2022-07-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${az.resourceId(userMsiResourceGroup, 'Microsoft.ManagedIdentity/userAssignedIdentities', userMsiName)}': {}
    }
  }
  properties: {
    buildTimeoutInMinutes: buildTimeoutInMinutes
    vmProfile: {
      vmSize: vmSize
      osDiskSizeGB: osDiskSizeGB
      userAssignedIdentities: userAssignedIdentities
      vnetConfig: !empty(subnetId) ? vnetConfig : null
    }
    source: imageSource
    customize: loadJsonContent('avdCustomizationSteps.json')
    distribute: distribute
    stagingResourceGroup: stagingResourceGroup
  }
}

output imageTemplateId string = imageTemplate.id
