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

> [!note] Please note the **aio-broker-insecure** service for enabling the internal communication with the MQTT broker on port 1883.

Deploy a workload that will simulate industrial assets and send data to the MQ Broker.

`kubectl apply -f simulator.yaml`

!IMAGE [simulatordeployment.png](instructions277358/simulatordeployment.png)

**9. Check topics with MQTT Explorer**

Go to the favourites bar and click the MQTT Explorer icon to open it, and click con **Connect** as indicated in the image. We can use this program to check the contents of the MQTT Broker.

!IMAGE[mqttconfig.png](instructions277358/mqttconfig.png)

MQTT uses MQTT Topics to organize messages. An MQTT topic is like an address used by the protocol to route messages between publishers and subscribers. Think of it as a specific channel or path where devices can send (publish) and receive (subscribe to) messages. Each topic can have multiple levels separated by slashes, such as home/livingroom/temperature, to organize data more effectivelycan be published to specific topics.

Our simulator is publishing messages to the **"iot/devices" topic** prefix. You can drill down through the topics to view incoming MQ messages written by the devices to specific MQTT topics.

!IMAGE [podinmqttexplorer.png](instructions277358/podinmqttexplorer.png)

> [!knowledge] Azure IoT Operations publishes its own self test messages to the azedge topic. This is useful to confirm that the MQ Broker is available and receiving messages.

***

## **Module 4 - Transform Data at Scale with Azure IoT Operations**

In this module you will learn the following skills:

* Learn about the Digital Operations Experience portal (DOE).
* How to use Dataflows to contextualize and send data edge to cloud.
* Deployment options and examples.

**Digital Operations Experience**

As part of the Operational Technology rol, Azure IoT Operations has dedicated portal where monitor and manage **Sites** and data transformations with **Dataflows**.

**Sites**

Azure Arc site manager allows you to manage and monitor your on-premises environments as **Azure Arc sites**. Arc sites are scoped to an Azure resource group or subscription and enable you to track connectivity, alerts, and updates across your environment. The experience is tailored for on-premises scenarios where infrastructure is often managed within a common physical boundary, such as a store, restaurant, or factory.

Please, click on View unassigned instances:

!IMAGE[Sites.png](instructions277358/Sites.png)

And select your instance from the list:

!IMAGE[Sites2.png](instructions277358/Sites2.png)

In this screen, you can check monitoring metrics of the Arc enabled cluster in Sites. Now, let's move to Dataflows on the left panel:

!IMAGE[Sites3.png](instructions277358/Sites3.png)

**Dataflows**

Dataflows is a built-in feature in Azure IoT Operations that allows you to connect various data sources and perform data operations, simplifying the setup of data paths to move, transform, and enrich data.
As part of Dataflows, Data Processor can be use to perform on-premises transformation in the data either by using Digital Opeartions Experience or via automation.

The configuration for a Dataflow can be done by means of different methods:
* With Kubernetes and Custom Resource Definitions (CRDs). Changes are only applyed on-prem and don't sync with DOE.
* Via Bicep automation: Changes are deployed on the Schema Registry and are synced to the edge. (Deployed Dataflows are visible on DOE).
* Via DOE: Desig your Dataflows and Data Processor Transformations with the UX and synch changes to the edge to perform on-prem contextualization.

You can write configurations for various use cases, such as:

* Transform data and send it back to MQTT
* Transform data and send it to the cloud
* Send data to the cloud or edge without transformation


By unsing DOE and the built in Dataflows interface:

!IMAGE[Dataflows1.png](instructions277358/Dataflows1.png)

You can create a new Dataflows selecting the Source, transforming data and selecting the dataflow endpoint:

!IMAGE[df2.png](instructions277358/df2.png)

For the sake of the time and to reduce complexity during this lab, we will generate this dataflows by Bicep automation. This automation will:

* Select a topic from the MQTT simulator we deployed on previous steps

* Send topic data to Event Hub

**1. To send the data to Event Hub, we need to retrieve some information on the resources already deployed in your resource group as a pre-requisite:**

* EventHub Namespace:

`export eventHubNamespace=$(az eventhubs namespace list --resource-group $RESOURCE_GROUP --query '[].name' -o tsv)`

* EventHub Namespace ID:

`export eventHubNamespaceId=$(az eventhubs namespace show --name $eventHubNamespace --resource-group $RESOURCE_GROUP --query id -o tsv)`

* EventHub Hostname:

`export eventHubNamespaceHost="${eventHubNamespace}.servicebus.windows.net:9093"`

**2. Azure IoT Operations needs to publish and subscribe to this EventHub so we need to grant permissions on the service principal for the MQTT Broker in charge of this task:**

* Retrieving IoT Operations extension Service Principal ID:

`export iotExtensionPrincipalId=$(az k8s-extension list --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --cluster-type connectedClusters --query "[?extensionType=='microsoft.iotoperations'].identity.principalId" -o tsv)`

* Assigning Azure Event Hubs Data Sender and Receiver roles to EventHub namespace:

`az role assignment create --assignee $iotExtensionPrincipalId --role "Azure Event Hubs Data Sender" --scope $eventHubNamespaceId`

`az role assignment create --assignee $iotExtensionPrincipalId --role "Azure Event Hubs Data Receiver" --scope $eventHubNamespaceId`

**3. In addition to this, we also need the Custom Locations name and the eventHub in the EventHub Namespace as the parameter of the Bicep file containing the dataflows automation:**

* Get CustomLocationName in a Resource Group:

`export customLocationName=$(az resource list --resource-group $RESOURCE_GROUP --resource-type "Microsoft.ExtendedLocation/customLocations" --query '[].name' -o tsv)`

* List all Event Hubs in a specific namespace:

`export eventHubName=$(az eventhubs eventhub list --resource-group $RESOURCE_GROUP --namespace-name $eventHubNamespace --query '[].name' -o tsv)`

* Deploy Dataflows:

`export dataflowBicepTemplatePath="dataflows.bicep"`

`az deployment group create --resource-group $RESOURCE_GROUP --template-file $dataflowBicepTemplatePath --parameters aioInstanceName="aio-lab460" eventHubNamespaceHost=$eventHubNamespaceHost eventHubName=$eventHubName customLocationName=$customLocationName`

**4. Check your Dataflows deployment:**

* In DOE and Dataflows:

Please go to the DOE instance and check your new Dataflows:

* In EventHub DataExplorer:

Please go to your Resource Group in Azure Portal and navigate to your EventHub Namespaces. Then click on DataExplorer and select: