@lab.Title

Login to your VM with the following credentials...

**Username: ++@lab.VirtualMachine(Win11-Pro-Base-VM).Username++**

**Password: +++@lab.VirtualMachine(Win11-Pro-Base-VM).Password+++** 

<br>

---

## Lab environment

You are connected to a Windows 11 machine that has been preconfigured with development tools like Visual Studio Code, Azure CLI, kubectl, Azure Data Studio, and more. Throughout this session, you will be using the tools in this environment and in the [Azure portal](https://portal.azure.com/#home) to complete the lab different lab modules.

## Module 1 - Computer vision in action

!Intro to computer vision

### Get the starter code

Open Visual Studio Code to get started by clicking the icon on the desktop. Once its open, click the "Clone Repository" button.

!IMAGE[b50tnd3s.jpg](instructions275881/b50tnd3s.jpg)

Enter ```https://github.com/dkirby-ms/IPD2024``` to get the starter code for the labs. Select the default folder location and then click through the prompts to trust the folder and open the cloned repository in Visual Studio Code.

!IMAGE[j1skzaee.jpg](instructions275881/j1skzaee.jpg)

### 

### YOLO on Jupyter

From inside VSCode, open up the cv-image.ipynb and follow the prompts. 

### OpenAI on Jupyter

From inside VSCode, open up the cv-image.ipynb and follow the prompts. 

### YOLO IN ROOM CAMERAS

For this exercise, open up the YOLOLIVE.ipynb and follow the prompts.

### OpenAI IN ROOM CAMERAS

For this exercise, open up the YOLOLIVE.ipynb and follow the prompts.

### YOLO TO test.mosquitto.org

## Lab Module - Copilot for Predictive Analytics

## Lab Module - Deploy a computer vision solution at the edge

In this lab, you have access to an Ubuntu 22.04 LTS server with 8 processors and 16GB memory. You will use this as an edge Kubernetes host for running an industrial AI solution. To save a little time, the server has already been configured with Rancher K3s. Let's take a look at the environment now. Click on the Windows Terminal icon on the desktop to open a shell.

Remote into the Ubuntu server using ssh.

    ssh 192.168.1.100

>[!help]The password is: @lab.VirtualMachine(UbuntuServer22.04).Password
>[!alert]The IP address of the Ubuntu server may be 192.168.1.101

Once you're in, use kubectl to check the status of the nodes of the cluster. 

    kubectl get nodes

!IMAGE[xncv6lf6.jpg](instructions275881/xncv6lf6.jpg)

Great, now let's check the running pods.

    kubectl get pods -A

!IMAGE[znpwctui.jpg](instructions275881/znpwctui.jpg)

If everything looks good then this cluster can be onboarded to Azure with Azure Arc. Login to Azure with a device code. Use the Azure credentials available in the lab guide "Resources" tab.

    az login --use-device-code

>[!hint]When prompted, select the default Azure subscription.

## Onboard K3s to Azure Arc

Once logged in, use the following command to onboard the kubernetes cluster to Azure with Azure Arc.

    az connectedk8s connect --name arc-k3s --resource-group rg-Edge --enable-oidc-issuer --enable-workload-identity

>[!alert]You may need to run this command again if you see an error message trying to download kubectl.

>[!tip]The resource group "rg-Edge" has been pre-created for this lab.

It will take a few minutes to onboard the cluster. In the meantime, you can open Azure portal and navigate to your resource group. When the cluster is finished onboarding, you will be able to view it in the portal.

!IMAGE[5x563n7i.jpg](instructions275881/5x563n7i.jpg)

Before we can deploy Azure IOT Operations, we need to enable the custom locations feature on the cluster. Run this script to quickly enable the feature.

    ./aio-prep.sh

>[!hint]The password is @lab.VirtualMachine(UbuntuServer22.04).Password

### Deploy Azure IOT Operations

First install the CLI extension for Azure IOT Operations (AIO).

    az extension add --upgrade --name azure-iot-ops

Next, verify that the host is ready.

    az iot ops verify-host

We will need some cloud resources in Azure to use with Azure IoT Operations - a storage account and keyvault. For this lab, the storage account and keyvault have been created to save time. We can get the identifiers of these resources and store them in a shell variable using the next two commands. First get the keyvault id.

    export AKV_ID=$(az keyvault list --query [].id -o tsv)

Next get the storage account.

    export STORAGE=$(az storage account list --resource-group rg-Edge -o tsv --query [].name)

>[!hint]If you want to see the values of the variables we just created, you can "echo" them ```echo $STORAGE```, ```echo $AKV_ID```

Now that we have these cloud resources, we can create a schema registry for Azure IoT Operations.

    az iot ops schema registry create --name schema@lab.LabInstance.GlobalId --resource-group rg-Edge --registry-namespace $STORAGE --sa-resource-id $(az storage account show --name $STORAGE --resource-group rg-Edge -o tsv --query id)

We will need the id of the resource we just created in a later step. 

    export SCHEMA_REGISTRY_RESOURCE_ID=$(az iot ops schema registry show --name schema@lab.LabInstance.GlobalId --resource-group rg-Edge -o tsv --query id)

>[!knowledge] Schemas are documents that describe the format of a message and its contents to enable processing and contextualization. The schema registry is a synchronized repository in the cloud and at the edge. The schema registry stores the definitions of messages coming from edge assets, and then exposes an API to access those schemas at the edge. The schema registry is backed by a cloud storage account. This storage account was pre-created as part of the lab setup.

Now you can initialize the cluster for the AIO services. This command  will take a few minutes to complete.

    az iot ops init --cluster arc-k3s --resource-group rg-Edge 

!IMAGE[8acn4r2e.jpg](instructions275881/8acn4r2e.jpg)

Finally, we can deploy the AIO solution. This somewhat lengthy command will take some time to type out :)

    az iot ops create --name aio-ignite --cluster arc-k3s --resource-group rg-Edge --sr-resource-id $SCHEMA_REGISTRY_RESOURCE_ID --broker-frontend-replicas 1 --broker-frontend-workers 1 --broker-backend-part 1 --broker-backend-workers 1 --broker-backend-rf 2 --broker-mem-profile Low --add-insecure-listener true

!IMAGE[yibsdkr5.jpg](instructions275881/yibsdkr5.jpg)

>[!knowledge]For this lab, we are using an insecure listener for the MQ Broker. In a production environment, you can secure this endpoint using TLS and a certificate.

### Send data to MQ

We can use a local MQTT client to easily check that messages are being sent to the AIO MQ broker. First let's identity the service where the MQ broker is listening. Run the following command.

    kubectl get svc -n azure-iot-operations

The service called mq-broker-insecure is listening on 1883 of the load balancer external IP address. We will use this address in the next step. Open up MQTT Explorer by clicking the icon on the desktop.

!IMAGE[h4989xx3.jpg](instructions275881/h4989xx3.jpg)

### Collect data from industrial assets with a dataflow

Deploy a workload that will simulate industrial assets and send data to the MQ Broker. 
    
    kubectl apply -f artifacts/simulator.yaml

Go to the Windows desktop and click the MQTT Explorer icon to open it. We can use this program to check the contents of the [MQ Broker](https://learn.microsoft.com/en-us/azure/iot-operations/manage-mqtt-broker/overview-iot-mq).

!IMAGE[hlc0jso6.jpg](instructions275881/hlc0jso6.jpg)

In the host field of the new connection window, enter the IP address you noted earlier with kubectl. Click connect when ready.

!IMAGE[86q8kg2a.jpg](instructions275881/86q8kg2a.jpg)

>[!note]Due to the Kubernetes configuration, the IP address will be the same as the IP you used to SSH into the Ubuntu server.

MQTT uses MQTT Topics to organize messages. An MQTT topic is like an address used by the protocol to route messages between publishers and subscribers. Think of it as a specific channel or path where devices can send (publish) and receive (subscribe to) messages. Each topic can have multiple levels separated by slashes, such as home/livingroom/temperature, to organize data more effectivelycan be published to specific topics.

Our simulator is publishing messages to the "iot/devices" topic prefix. You can drill down through the topics to view incoming MQ messages written by the devices to specific MQTT topics.

!IMAGE[4y7o797z.jpg](instructions275881/4y7o797z.jpg)

>[!knowledge]Azure IoT Operations publishes its own self test messages to the azedge topic. This is useful to confirm that the MQ Broker is available and receiving messages.

### Build edge-to-cloud dataflow

[Dataflows](https://learn.microsoft.com/en-us/azure/iot-operations/connect-to-cloud/overview-dataflow) allow you to connect various data sources and perform data operations, simplifying the setup of data paths to move, transform, and enrich data. The dataflow component is part of Azure IoT Operations. The configuration for a dataflow is done via Kubernetes custom resource definitions (CRDs).

You can write configurations for various use cases, such as:

-Transform data and send it back to MQTT
-Transform data and send it to the cloud
-Send data to the cloud or edge without transformation

## Lab Module 3 - Scale the solution

### GitOps

### Observability

### Defender

## **Congratulations, you have reached the end of this lab.**