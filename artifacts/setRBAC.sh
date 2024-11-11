#!/bin/bash
export eventHubNamespace=$(az eventhubs namespace list --resource-group rg-Edge --query '[].name' -o tsv)
export eventHubNamespaceId=$(az eventhubs namespace show --name $eventHubNamespace --resource-group rg-Edge --query id -o tsv)
export eventHubNamespaceHost="${eventHubNamespace}.servicebus.windows.net:9093"
export iotExtensionPrincipalId=$(az k8s-extension list --resource-group rg-Edge --cluster-name arc-k3s --cluster-type connectedClusters --query "[?extensionType=='microsoft.iotoperations'].identity.principalId" -o tsv --only-show-errors)
az role assignment create --assignee $iotExtensionPrincipalId --role "Azure Event Hubs Data Sender" --scope $eventHubNamespaceId
az role assignment create --assignee $iotExtensionPrincipalId --role "Azure Event Hubs Data Receiver" --scope $eventHubNamespaceId



