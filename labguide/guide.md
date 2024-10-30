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

### Deploy Azure IOT Operations

Now we will deploy Azure IOT Operations on our Arc-enabled cluster.

First install the CLI extension for Azure IOT Operations (AIO).

    az extension add --upgrade --name azure-iot-ops

Now create a storage account that we will use with AIO.

Leave cloud shell open and go back to Azure portal and enter "Azure IoT Operations" in the search box and select it.

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