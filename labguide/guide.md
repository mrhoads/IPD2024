@lab.Title

Login to your VM with the following credentials...

**Username: ++@lab.VirtualMachine(Win11-Pro-Base-VM).Username++**

**Password: +++@lab.VirtualMachine(Win11-Pro-Base-VM).Password+++** 

<br>

---

## Lab environment

You are connected to a Windows 11 machine that has been preconfigured with development tools like Visual Studio Code, Azure CLI, kubectl, Azure Data Studio, and more. Throughout this session, you will be using the tools in this environment and in the [Azure portal](https://portal.azure.com/#home) to complete the lab different lab modules.

### Dev environment

Open VS Code and ...

### Azure portal

Navigate to [Azure portal](https://portal.azure.com/#home) and login using the credentials in the Resource tab in the upper left. 

## Lab Module 1 - Computer vision POC

Open Visual Studio Code.

Clone notebooks repo.

### YOLO

### YOLO IN ROOM CAMERAS

### MQ / inferencing pipeline

### YOLO TO MQ

## Lab Module - Copilot for Predictive Analytics

## Lab Module - Deploy a computer vision solution at the edge

In this lab, you have access to an Ubu 22.04 LTS server with XX processors and XX memory. You will use as an edge Kubernetes host for running our industrial AI solution. To save a little time, the server has already been configured with Rancher K3s. Let's take a look at the environment now. Click on Ubuntu Server and login using the provided credentials.

!IMAGE[Ubuntu]()

Once you're in, use kubectl to check the status of the nodes of the cluster. 

    kubectl get nodes

Great, now let's check the running pods.

    kubectl get pods -A

!Image[pods]()

    az connectedk8s connect -n arc-k3s -g rg-Edge --enable-oidc-issuer --enable-workload-identity

    !!!Knowledge - You may need to run this command if you see an error message trying to download kubectl.

!Image[arck3s]()

Now run this script to prep the cluster for AIO.

    ```bash
    export ISSUER_URL_ID=$(az connectedk8s show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query oidcIssuerProfile.issuerUrl --output tsv)

    #Enabling Service Account in k3s:
    {
    echo "kube-apiserver-arg:"
    echo " - service-account-issuer=$ISSUER_URL_ID"
    echo " - service-account-max-token-expiration=24h"
    } | sudo tee -a /etc/rancher/k3s/config.yaml > /dev/null

    export OBJECT_ID=$(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)
    az connectedk8s enable-features -n $CLUSTER_NAME -g $RESOURCE_GROUP --custom-locations-oid $OBJECT_ID --features cluster-connect custom-locations

    sudo systemctl restart k3s
    ```

Finally, we can check in Azure portal that our cluster is visible as a resource.

!Image[Azure portal k3s]()

We are now ready to deploy Azure IOT Operations.

### Deploy Azure IOT Operations

Now we will deploy Azure IOT Operations on our Arc-enabled cluster.

First install the CLI extension for Azure IOT Operations (AIO).

    az extension add --upgrade --name azure-iot-ops

Next, verify that the host is ready.

    az iot ops verify-host

!IMAGE[aziotopsverify]()

Now create a storage account and keyvault that we will use with Azure IoT Operations. You can run the following script to create the vault and storage account with the correct settings.

    randomstr=$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)
    sa=ig24prel18${randomstr}
    AKV_NAME="akvignite"${randomstr}
    az keyvault create --enable-rbac-authorization --name $AKV_NAME --resource-group $RESOURCE_GROUP
    export AKV_ID=$(az keyvault show --name $AKV_NAME --resource-group $RESOURCE_GROUP -o tsv --query id)

Next create a schema registry for Azure IoT Operations.

    schemaName=schema${randomstr}
    az iot ops schema registry create --name $schemaName --resource-group $RESOURCE_GROUP --registry-namespace $sa --sa-resource-id $(az storage account show --name $sa --resource-group $RESOURCE_GROUP -o tsv --query id)
    export SCHEMA_REGISTRY_RESOURCE_ID=$(az iot ops schema registry show --name $schemaName --resource-group $RESOURCE_GROUP -o tsv --query id)

!!!Knowledge - The schema registry is a synchronized repository in the cloud and at the edge. The schema registry stores the definitions of messages coming from edge assets, and then exposes an API to access those schemas at the edge. Schemas are documents that describe the format of a message and its contents to enable processing and contextualization.

Now you can initialize the cluster for the AIO services. This command  will take a few minutes to complete.

    az iot ops init --cluster $CLUSTER_NAME --resource-group $RESOURCE_GROUP --sr-resource-id $SCHEMA_REGISTRY_RESOURCE_ID

!IMAGE[iotOpsInit]()

Finally, we can deploy the AIO solution. This command will also take some time.

    az iot ops create --name aio-ignite --cluster $CLUSTER_NAME --resource-group $RESOURCE_GROUP --enable-rsync true --add-insecure-listener true

!IMAGE[iotOpsCreate]()

!!!Knowledge - For this lab, we are using an insecure listener for the MQ Broker. In a production environment, you can secure this endpoint using TLS and a certificate.

### Send data to MQ

We can use a local MQTT client to easily check that messages are being sent to the AIO MQ broker. First let's identity the service where the MQ broker is listening. Run the following command.

    kubectl get svc -n azure-iot-operations

Get the IP address of the service called mq-broker-insecure. We will use this address in the next step. Open up MQTT Explorer by clicking the icon on the desktop.

!IMAGE[MQTTexplorer.jpg]()

### Setup video streams

Use kubectl to deploy containers that provide a "virtual" RTSP feed. 
    kubectl apply -f rtsp.yaml

### Deploy footfall inferencing API

    kubectl apply -f 
kubec
### Confirm that messages being generated on MQ.

    kubectl apply -f footfall.yaml
    kubectl apply -f shopper-analytics.yaml

### Deploy 

!!Screenshot

Deploy new instance

## Lab Module 3 - Scale the solution

### GitOps

### Observability

### Defender

## **Congratulations, you have reached the end of this lab.**