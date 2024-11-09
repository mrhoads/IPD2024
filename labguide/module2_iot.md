## **Lab 2 - Edge-to-Cloud Industrial IoT**

In this lab, you will explore the [MQ Broker component](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/overview-iot-mq) of Azure IoT Operations, which is essential for managing and routing messages between IoT devices. The MQ Broker facilitates communication by using MQTT (Message Queuing Telemetry Transport), a lightweight and efficient messaging protocol. You will learn how to set up and interact with the MQ Broker, deploy data simulators, and use tools like MQTT Explorer to monitor and analyze the messages being exchanged. This hands-on experience will provide you with a deeper understanding of how Azure IoT Operations can be leveraged to build robust and scalable industrial IoT solution

[MQTT (Message Queuing Telemetry Transport)](https://en.wikipedia.org/wiki/MQTT) is a lightweight messaging protocol that is highly effective in AI use cases due to its efficient bandwidth usage and low latency. It enables seamless communication between IoT devices and AI systems, allowing for real-time data collection and processing. This is particularly powerful in scenarios such as predictive maintenance, smart cities, and autonomous vehicles, where timely and reliable data transmission is crucial. By leveraging MQTT, AI applications can receive continuous streams of data from various sensors and devices, facilitating rapid decision-making and enhancing the overall intelligence and responsiveness of the system.

### **Module 2.1 - Arc-enable a Rancher K3s cluster**

In this lab, you have access to an Ubuntu 22.04 LTS server with 8 processors and 16GB memory. You will use this as an edge Kubernetes host for running an industrial AI solution. To save a little time, the server has already been configured with Rancher K3s. Let's take a look at the environment now. Click on the Windows Terminal icon on the desktop to open a shell.

#### **Step 1 - Remote into the Ubuntu server using ssh**

`ssh 192.168.1.100`

>[!help]The password is: +++@lab.VirtualMachine(UbuntuServer22.04).Password+++
>[!alert]The IP address of the Ubuntu server may be 192.168.1.101

#### **Step 2 - Check cluster status**

Once you're in, use kubectl to check the status of the nodes of the cluster.

`kubectl get nodes`

!IMAGE[kubectl get nodes](img/step2a.png)

Great, now let's check the running pods.

`kubectl get pods -A`

!IMAGE[kubectl get pods](img/step2b.png)

If everything looks good then this cluster can be onboarded to Azure with Azure Arc. Login to Azure with a device code using the following command. Use the Azure credentials available in the lab guide "Resources" tab.

`az login --use-device-code`

!IMAGE[Azure device code login](img/step2c.png)

>[!hint]When prompted, select the default Azure subscription.

#### **Step 3 - Connect the cluster to Azure Arc**

Once logged in, use the following command to onboard the kubernetes cluster to Azure with Azure Arc.

`az connectedk8s connect --name arc-k3s --resource-group rg-Edge --enable-oidc-issuer --enable-workload-identity`

>[!alert]You may need to run this command again if you see an error message trying to download kubectl.

>[!tip]The resource group "rg-Edge" has been pre-created for this lab.

It will take a few minutes to onboard the cluster. In the meantime, you can open Azure portal and navigate to your resource group. When the cluster is finished onboarding, you will be able to view it in the portal.

!IMAGE[5x563n7i.jpg](instructions275881/5x563n7i.jpg)

#### **Step 4 - Enable the custom locations feature of the cluster**

Before we can deploy Azure IOT Operations, we need to enable the custom locations feature on the cluster. Run this script to quickly enable the feature.

`./aio-prep.sh`

>[!hint]The password is @lab.VirtualMachine(UbuntuServer22.04).Password

### **Module 2.2 - Deploy Azure IOT Operations**

#### **Step 1 - Prepare to install Azure IOT Operations**

First install the CLI extension for Azure IOT Operations.

`az extension add --upgrade --name azure-iot-ops`

Next, verify that the host is ready.

`az iot ops verify-host`

!IMAGE[Verify IOT host](./img/module2.2.1a.png)

#### **Step 2 - Prepare to create a schema registry**

We will need some cloud resources in Azure to use with Azure IoT Operations including a [schema registry](https://learn.microsoft.com/azure/event-hubs/schema-registry-concepts). For this lab, the storage account and keyvault have been created to save time. We can get the identifiers of these resources and store them in shell variables.

Next get the storage account and store it in an environment variable for ease of use in next steps.

`export STORAGE=$(az storage account list --resource-group rg-Edge -o tsv --query [].name)`

>[!hint]If you want to see the values of the variables we just created, you can "echo" them ```echo $STORAGE```

!IMAGE[echo storage](./img/echo-storage.png)

#### **Step 3 - Create a schema registry**

Now that we have these cloud resources, we can create a schema registry for Azure IoT Operations.

`az iot ops schema registry create --name schema@lab.LabInstance.GlobalId --resource-group rg-Edge --registry-namespace $STORAGE --sa-resource-id $(az storage account show --name $STORAGE --resource-group rg-Edge -o tsv --query id)`

!IMAGE[Create schema registry](./img/createschemareg.png)

We will need the id of the resource we just created in a later step.

`export SCHEMA_REGISTRY_RESOURCE_ID=$(az iot ops schema registry show --name schema@lab.LabInstance.GlobalId --resource-group rg-Edge -o tsv --query id)`

>[!knowledge] Schemas are documents that describe the format of a message and its contents to enable processing and contextualization. The schema registry is a synchronized repository in the cloud and at the edge. The schema registry stores the definitions of messages coming from edge assets, and then exposes an API to access those schemas at the edge. The schema registry is backed by a cloud storage account. This storage account was pre-created as part of the lab setup.

#### **Step 4 - Initialize Azure IoT Operations**

Now you can initialize the cluster for the Azure IoT Operations services. This command  will take a few minutes to complete.

`az iot ops init --cluster arc-k3s --resource-group rg-Edge`

!IMAGE[iot init](./img/iotinit.png)

#### **Step 5 - Deploy Azure IoT Operations**

Next, we can deploy the AIO solution. This somewhat lengthy command will take some time to type out.

`az iot ops create --name aio-ignite --cluster arc-k3s --resource-group rg-Edge --sr-resource-id $SCHEMA_REGISTRY_RESOURCE_ID --broker-frontend-replicas 1 --broker-frontend-workers 1 --broker-backend-part 1 --broker-backend-workers 1 --broker-backend-rf 2 --broker-mem-profile Low --add-insecure-listener true`

!IMAGE[iot create](./img/iotcreate.png)

>[!knowledge]For this lab, we are using an insecure listener for the MQ Broker. In a production environment, you can secure this endpoint using TLS and a certificate.

#### **Step 6 - Enable secure settings**

Secrets Management for Azure IoT Operations uses Secret Store extension to sync the secrets from an Azure Key Vault and store them on the edge as Kubernetes secrets. Create a name for the managed identity and store it in an environment variable.

`export USER_ASSIGNED_MI_NAME="aiomi@lab.LabInstance.GlobalId"`

Now create the identity.

`az identity create --name $USER_ASSIGNED_MI_NAME --resource-group rg-Edge`

!IMAGE[Create identity](./img/create_ssmi.png)

Get the resource ID of the user-assigned managed identity you just created.

`export USER_ASSIGNED_MI_RESOURCE_ID=$(az identity show --name $USER_ASSIGNED_MI_NAME --resource-group rg-Edge --query id --output tsv)`

!IMAGE[View identity](./img/viewssmi.png)

Get the keyvault id of the keyvault that was created for you as part of the lab initializing..

`export AKV_ID=$(az keyvault list --query [].id -o tsv)`

Finally, enable secret synchronization, using the variables we saved.

`az iot ops secretsync enable --name "aio-ignite" --resource-group rg-Edge --mi-user-assigned $USER_ASSIGNED_MI_RESOURCE_ID --kv-resource-id @lab.Variable(Azure_KeyVault_ID)`

!IMAGE[Create secret sync](./img/secretsyncenable.png)

### **Module 2.3 - Explore MQTT**

MQTT uses MQTT Topics to organize messages. An MQTT topic is like an address used by the protocol to route messages between publishers and subscribers. Think of it as a specific channel or path where devices can send (publish) and receive (subscribe to) messages. Each topic can have multiple levels separated by slashes, such as home/livingroom/temperature, to organize data more effectivelycan be published to specific topics.

We can use a local MQTT client to easily check that the [MQ Broker](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/overview-iot-mq) component of Azure IoT Operations is working normally.

#### **Step 1 - Get the MQ broker endpoint**

First let's identity the service where the MQ broker is listening. Run the following command.

`kubectl get svc -n azure-iot-operations`

!IMAGE[Kubectl get svc](./img/ksvc.png)

> [!note] Please note the **aio-broker-insecure** service for enabling the internal communication with the MQTT broker on port 1883.

#### **Step 2 - Deploy a data simulator**

We can simulate real industrial assets such as commercial refrigeration and oven units, HVAC systems, Deploy a workload that will simulate industrial assets and send data to the MQ Broker.

`kubectl apply -f simulator.yaml`

!IMAGE [simulatordeployment.png](instructions277358/simulatordeployment.png)

#### **Step 3 - Check topics with MQTT Explorer**

Minimize the Terminal window and go to the Windows desktop to find the icon for MQTT Explorer. Double click to open it.

!IMAGE[MQTT Icon](./img/mqtticon.png)

The connection to Azure IoT Operations is already setup, so click Connect.

!IMAGE[MQTT explorer](img/mqtt2.png)

Our simulator is publishing messages to the **"iot/devices" topic** prefix. You can drill down through the topics to view incoming MQ messages written by the devices to specific MQTT topics. By clicking on an indivudal message within a topic you can view its contents.

!IMAGE[MQTT explorer](img/mqtt3.png)

> [!knowledge] Azure IoT Operations publishes its own self test messages to the azedge topic. This is useful to confirm that the MQ Broker is available and receiving messages.

Now let's move on to sending data from the MQ broker downstream through a data pipeline.

### **Module 2.4 - Bridge IT and OT Azure IoT Operations**

Azure IoT Operations is designed to bridge the gap between IT (Information Technology) and OT (Operational Technology) by providing two distinct components tailored for each group. For IT workers, Azure IoT Operations offers robust cloud-based management and analytics tools, enabling seamless integration with existing IT infrastructure and cloud services. This includes capabilities like [Azure Arc](https://learn.microsoft.com/azure/azure-arc/overview) for managing hybrid environments and [Dataflows](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/overview-dataflow) for building data pipelines. For OT workers, Azure IoT Operations provides edge solutions that ensure reliable and real-time data processing and device management on the factory floor or in other operational environments. This includes tools like [MQTT Broker](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/overview-iot-mq) for efficient message routing and [Data Processor](https://learn.microsoft.com/azure/iot-operations/manage-dataflows/data-processor) for on-premises data transformation. By catering to the needs of both IT and OT, Azure IoT Operations enables a unified approach to managing and optimizing industrial IoT solutions.

#### **Step 1 - Open the Azure IoT Operations portal**

Open Microsoft Edge by clicking the icon on the desktop, then click the bookmark for the Azure IoT Operations experience portal.

!IMAGE[MQTT explorer](img/aioportal.png)

Click on Get Started and then on View unassigned instances.

!IMAGE[View unassigned](./img/viewunassigned.png)

And select your instance from the list.

!IMAGE[View instance](./img/clickinstance.png)

In this screen, you can check monitoring metrics of the Arc enabled cluster in Sites. Now, let's move to Dataflows on the left panel.

!IMAGE[Click dataflows](./img/press-dataflows.png)

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