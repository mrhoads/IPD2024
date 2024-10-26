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

## Lab Module 2 - Copilot for Predictive Analytics

## Lab Module 3 - Deploy a computer vision solution at the edge

### Arc-enable a Kubernetes cluster

We will simulate an edge-based Kubernetes cluster by using virtualization. Let's go ahead and open Azure cloud shell by clicking on the !IMAGE[3mduomrb.jpg](instructions275881/3mduomrb.jpg) icon in the top right. Select **Bash** as your environment and create a storage account to go with it as shown in the screenshot.

!IMAGE[5sapho2w.jpg](instructions275881/5sapho2w.jpg)

!IMAGE[x20cjpfh.jpg](instructions275881/x20cjpfh.jpg)

Once Cloud shell is open type the following command and create a resource group to work in.

    az group create -n rg-Edge -l eastus2

Cool. Now let's create a new group and deploy a new Ubuntu VM, which will take a few minutes to provision.
    
    az vm create -g rg-Edge \
    --name vm-Edge \
    --image Ubuntu2204 \
    --size Standard_d16s_v5 \
    --assign-identity \
    --role "Contributor" \
    --scope "/subscriptions/@lab.CloudSubscription.Id/resourcegroups/rg-Edge" \
    --generate-ssh-keys

Now that the VM is provisioned, let's deploy a custom script extension on it that configures it as a Rancher K3s cluster.

    az vm extension set \
    --resource-group rg-Edge \
    --vm-name vm-Edge \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --settings '{"fileUris":["https://raw.githubusercontent.com/dkirby-ms/MiscARM/refs/heads/main/installk3s.sh"], "commandToExecute":"sh installk3s.sh rg-edge"}'

Once this script extension completes its job successfully you will have a Rancher K3s cluster ready to work with on the Ubuntu VM. Now we can remote into the VM and take a look around. Close Cloud shell and navigate to your Virtual machine in the Azure portal, select "Connect" and then connect using the 'SSH using Azure CLI' option. 

!IMAGE[rerlw7an.jpg](instructions275881/rerlw7an.jpg)

Once you are in the VM let's confirm that Kubernetes is running. 

    kubectl get nodes

Now login to Azure from inside the Ubuntu VM using a device code. Select the default subscription when prompted.

    az login --use-device-code

### Deploy Azure IOT Operations

Now we will deploy Azure IOT Operations on our Arc-enabled cluster. 

First install the CLI extension for Azure IOT Operations (AIO).

    az extension add --upgrade --name azure-iot-ops

Now create a storage account that we will use with AIO.

Leave cloud shell open and go back to Azure portal and enter "Azure IoT Operations" in the search box and select it.

### Deploy the backend systems

    kubectl apply -f mssql.yaml
    kubectl apply -f influxdb.yaml
    kubectl apply -f mssql-seutp.yaml
    kubectl apply -f influxdb-setup.yaml

### Deploy inferencing APIs

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