## Lab 2 - Edge-to-Cloud Industrial IoT

In this lab, you have access to an Ubuntu 22.04 LTS server with 8 processors and 16GB memory. You will use this as an edge Kubernetes host for running an industrial AI solution. To save a little time, the server has already been configured with Rancher K3s. Let's take a look at the environment now. Click on the Windows Terminal icon on the desktop to open a shell.

### Module 2.1 - Arc-enable a Rancher K3s cluster

#### Step 1 - Remote into the Ubuntu server using ssh.

    ssh 192.168.1.100

>[!help]The password is: @lab.VirtualMachine(UbuntuServer22.04).Password
>[!alert]The IP address of the Ubuntu server may be 192.168.1.101

#### Step 2 - Check cluster status.

Once you're in, use kubectl to check the status of the nodes of the cluster. 

    kubectl get nodes

!IMAGE[xncv6lf6.jpg](instructions275881/xncv6lf6.jpg)

Great, now let's check the running pods.

    kubectl get pods -A

!IMAGE[znpwctui.jpg](instructions275881/znpwctui.jpg)

If everything looks good then this cluster can be onboarded to Azure with Azure Arc. Login to Azure with a device code. Use the Azure credentials available in the lab guide "Resources" tab.

    az login --use-device-code

>[!hint]When prompted, select the default Azure subscription.

#### Step 3 - Connect the cluster to Azure Arc

Once logged in, use the following command to onboard the kubernetes cluster to Azure with Azure Arc.

    az connectedk8s connect --name arc-k3s --resource-group rg-Edge --enable-oidc-issuer --enable-workload-identity

>[!alert]You may need to run this command again if you see an error message trying to download kubectl.

>[!tip]The resource group "rg-Edge" has been pre-created for this lab.

It will take a few minutes to onboard the cluster. In the meantime, you can open Azure portal and navigate to your resource group. When the cluster is finished onboarding, you will be able to view it in the portal.

!IMAGE[5x563n7i.jpg](instructions275881/5x563n7i.jpg)

#### Step 4 - Enable the custom locations feature of the cluster.

Before we can deploy Azure IOT Operations, we need to enable the custom locations feature on the cluster. Run this script to quickly enable the feature.

    ./aio-prep.sh

>[!hint]The password is @lab.VirtualMachine(UbuntuServer22.04).Password

### Module 2.2 - Deploy Azure IOT Operations

#### Step 1 - Prepare to install Azure IOT Operations.

First install the CLI extension for Azure IOT Operations.

    az extension add --upgrade --name azure-iot-ops

Next, verify that the host is ready.

    az iot ops verify-host

#### Step 2 - Prepare to create a schema registry.

We will need some cloud resources in Azure to use with Azure IoT Operations including a [schema registry](https://learn.microsoft.com/azure/event-hubs/schema-registry-concepts). For this lab, the storage account and keyvault have been created to save time. We can get the identifiers of these resources and store them in shell variables.

Next get the storage account.

    export STORAGE=$(az storage account list --resource-group rg-Edge -o tsv --query [].name)

>[!hint]If you want to see the values of the variables we just created, you can "echo" them ```echo $STORAGE```

#### Step 3 - Create a schema registry.

Now that we have these cloud resources, we can create a schema registry for Azure IoT Operations.

    az iot ops schema registry create --name schema@lab.LabInstance.GlobalId --resource-group rg-Edge --registry-namespace $STORAGE --sa-resource-id $(az storage account show --name $STORAGE --resource-group rg-Edge -o tsv --query id)

We will need the id of the resource we just created in a later step. 

    export SCHEMA_REGISTRY_RESOURCE_ID=$(az iot ops schema registry show --name schema@lab.LabInstance.GlobalId --resource-group rg-Edge -o tsv --query id)

>[!knowledge] Schemas are documents that describe the format of a message and its contents to enable processing and contextualization. The schema registry is a synchronized repository in the cloud and at the edge. The schema registry stores the definitions of messages coming from edge assets, and then exposes an API to access those schemas at the edge. The schema registry is backed by a cloud storage account. This storage account was pre-created as part of the lab setup.

#### Step 4 - Initialize Azure IoT Operations

Now you can initialize the cluster for the Azure IoT Operations services. This command  will take a few minutes to complete.

    az iot ops init --cluster arc-k3s --resource-group rg-Edge

!IMAGE[8acn4r2e.jpg](instructions275881/8acn4r2e.jpg)

#### Step 5 - Deploy Azure IoT Operations

Next, we can deploy the AIO solution. This somewhat lengthy command will take some time to type out :)

    az iot ops create --name aio-ignite --cluster arc-k3s --resource-group rg-Edge --sr-resource-id $SCHEMA_REGISTRY_RESOURCE_ID --broker-frontend-replicas 1 --broker-frontend-workers 1 --broker-backend-part 1 --broker-backend-workers 1 --broker-backend-rf 2 --broker-mem-profile Low --add-insecure-listener true

!IMAGE[yibsdkr5.jpg](instructions275881/yibsdkr5.jpg)

>[!knowledge]For this lab, we are using an insecure listener for the MQ Broker. In a production environment, you can secure this endpoint using TLS and a certificate.

#### Step 6 - Enable secure settings

Secrets Management for Azure IoT Operations uses Secret Store extension to sync the secrets from an Azure Key Vault and store them on the edge as Kubernetes secrets. Create a name for the managed identity and store it in an environment variable.

    export USER_ASSIGNED_MI_NAME="aiomi@lab.LabInstance.GlobalId"

Now create the identity.

    az identity create --name $USER_ASSIGNED_MI_NAME --resource-group rg-Edge

Get the resource ID of the user-assigned managed identity:

    export USER_ASSIGNED_MI_RESOURCE_ID=$(az identity show --name $USER_ASSIGNED_MI_NAME --resource-group rg-Edge --query id --output tsv)

Get the keyvault id.

    export AKV_ID=$(az keyvault list --query [].id -o tsv)

Finally, enable secret synchronization, using the variables we saved in step 
    
    az iot ops secretsync enable --name "aio-ignite" --resource-group rg-Edge --mi-user-assigned $USER_ASSIGNED_MI_RESOURCE_ID --kv-resource-id @lab.Variable(Azure_KeyVault_ID)

### Module 2.3 - Explore MQTT

MQTT uses MQTT Topics to organize messages. An MQTT topic is like an address used by the protocol to route messages between publishers and subscribers. Think of it as a specific channel or path where devices can send (publish) and receive (subscribe to) messages. Each topic can have multiple levels separated by slashes, such as home/livingroom/temperature, to organize data more effectivelycan be published to specific topics.

We can use a local MQTT client to easily check that the [MQ Broker](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/overview-iot-mq) component of Azure IoT Operations is working normally. 

#### Step 1 - Get the MQ broker endpoint.

First let's identity the service where the MQ broker is listening. Run the following command.

    kubectl get svc -n azure-iot-operations

The service called mq-broker-insecure is listening on 1883 of the load balancer external IP address. We will use this address in the next step. 

#### Step 2 - Connect to the broker with MQTT Explorer

Open up MQTT Explorer by clicking the icon on the desktop.

!IMAGE[h4989xx3.jpg](instructions275881/h4989xx3.jpg)

We can use this program to check the contents of the [MQ Broker](https://learn.microsoft.com/en-us/azure/iot-operations/manage-mqtt-broker/overview-iot-mq).

!IMAGE[hlc0jso6.jpg](instructions275881/hlc0jso6.jpg)

In the host field of the new connection window, enter the IP address you noted earlier with kubectl. Click connect when ready.

!IMAGE[86q8kg2a.jpg](instructions275881/86q8kg2a.jpg)

>[!note]Due to the Kubernetes configuration, the IP address will be the same as the IP you used to SSH into the Ubuntu server.

#### Step 3 - Confirm MQ broker is available.

Click thru topics

### Module 2.4 - Explore Dataflows

[Dataflows](https://learn.microsoft.com/en-us/azure/iot-operations/connect-to-cloud/overview-dataflow) allow you to connect various data sources and perform data operations, simplifying the setup of data paths to move, transform, and enrich data. The dataflow component is part of Azure IoT Operations. The configuration for a dataflow is done via Kubernetes custom resource definitions (CRDs).

You can write configurations for various use cases, such as:

- Transform data and send it back to MQTT
- Transform data and send it to the cloud
- Send data to the cloud or edge without transformation

#### Step 2 - Simulate industrial assets telementry

Deploy a container that will simulate industrial assets and send data to the MQ Broker. 
    
    kubectl apply -f artifacts/simulator.yaml

Go back to the MQTT Explorer icon to open it. Our simulator is publishing messages to the "iot/devices" topic prefix. You can drill down through the topics to view incoming MQ messages written by the devices to specific MQTT topics.

!IMAGE[4y7o797z.jpg](instructions275881/4y7o797z.jpg)


#### Step 3 - Deploy dataflow yaml

## **WIP: Module 4 - Transform Data at Scale with Azure IoT Operations WIP**

Dataflows allow you to connect various data sources and perform data operations, simplifying the setup of data paths to move, transform, and enrich data. The dataflow component is part of Azure IoT Operations. The configuration for a dataflow is done via Kubernetes custom resource definitions (CRDs).

You can write configurations for various use cases, such as:

* Transform data and send it back to MQTT
* Transform data and send it to the cloud
* Send data to the cloud or edge without transformation

!IMAGE[Sites.png](instructions277358/Sites.png)

!IMAGE[Sites2.png](instructions277358/Sites2.png)

!IMAGE[Sites3.png](instructions277358/Sites3.png)

!IMAGE[Dataflows1.png](instructions277358/Dataflows1.png)

!IMAGE[df2.png](instructions277358/df2.png)

!IMAGE[df3.png](instructions277358/df3.png)!IMAGE[df4.png](instructions277358/df4.png)


**Assigning 'Azure Event Hubs Data Sender and Receiver roles to EventHub namespace:**

Retrieving IoT Operations extension principalId:

`export iotExtensionPrincipalId=$(az k8s-extension list --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --cluster-type connectedClusters --query "[?extensionType=='microsoft.iotoperations'].identity.principalId" -o tsv)`

- List all Event Hub Namespaces, Host, and ID in a Resource Group:

`export eventHubNamespace=$(az eventhubs namespace list --resource-group $RESOURCE_GROUP --query '[].name' -o tsv)`

`export eventHubNamespaceId=$(az eventhubs namespace show --name $eventHubNamespace --resource-group $RESOURCE_GROUP --query id -o tsv)`

`export eventHubNamespaceHost="${eventHubNamespace}.servicebus.windows.net:9093"`

- Roles assignment:

`az role assignment create --assignee $iotExtensionPrincipalId --role "Azure Event Hubs Data Sender" --scope $eventHubNamespaceId`

`az role assignment create --assignee $iotExtensionPrincipalId --role "Azure Event Hubs Data Receiver" --scope $eventHubNamespaceId`

**Get CustomLocationName in a Resource Group:**

`export customLocationName=$(az resource list --resource-group $RESOURCE_GROUP --resource-type "Microsoft.ExtendedLocation/customLocations" --query '[].name' -o tsv)`

**List all Event Hubs in a specific namespace:**

`export eventHubName=$(az eventhubs eventhub list --resource-group $RESOURCE_GROUP --namespace-name $evenHubNamespaceHost --query '[].name' -o tsv)`

**Deploy Dataflows:**

`export dataflowBicepTemplatePath="dataflows.bicep"`

`az deployment group create --resource-group $RESOURCE_GROUP --template-file $dataflowBicepTemplatePath --parameters aioInstanceName="aio-lab460" eventHubNamespaceHost=$eventHubNamespaceHost eventHubName=$eventHubName customLocationName=$customLocationName`

#### Step 4 - Azure portal
