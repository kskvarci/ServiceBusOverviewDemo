#!/bin/bash

# Params
resourceGroup1Name="ServiceBusDem-EastUS2"
resourceGroup2Name="ServiceBusDem-CentralUS"
resourceGroup1Location="eastus2"
resourceGroup2Location="centralus"
namespace1Name="namespace1ksk"
namespace2Name="namespace2ksk"
aliasName="namespacekskalias"

# Create RGs
az group create --name $resourceGroup1Name --location $resourceGroup1Location
az group create --name $resourceGroup2Name --location $resourceGroup2Location

# Deploy Primary Namespace
az deployment group create --name primaryns --resource-group $resourceGroup1Name --template-file azuredeploy-namespace.json --parameters namespaceName=$namespace1Name
# Create Topics and Queues
az deployment group create --name queuestopics --resource-group $resourceGroup1Name --template-file azuredeploy-queuestopics.json --parameters namespaceName=$namespace1Name

# Deploy Secondary Namespace
# No entities on this namespace as they will come over with replication
az deployment group create --name secondaryns --resource-group $resourceGroup2Name --template-file azuredeploy-namespace.json --parameters namespaceName=$namespace2Name

# Set up Geo-Replication
az deployment group create --name georep --resource-group $resourceGroup1Name --template-file azuredeploy-georeplication.json --parameters namespaceName=$namespace1Name pairedNamespaceName=$namespace2Name pairedNamespaceResourceGroup=$resourceGroup2Name aliasName=$aliasName