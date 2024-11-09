### Module 3.1 - Observability

Lab Scenario: Implementing Observability for Arc-enabled Kubernetes Clusters

In this lab, you'll explore how to observe the health and status of Arc-enabled Kubernetes clusters using Grafana and Azure Monitor. While there's overlap between these tools, this lab intends to show the core capabilities of both and discuss typical approaches used for monitoring.


## What do we mean by observability?

Observability in Kubernetes is crucial for maintaining the performance, reliability, and availability of applications. In industrial scenarios, this is crucial because the workloads being deployed are critical for worker safety, manufacturing, and a host of other reasons.  Knowing that a system is healthy or, conversely, knowing that a system is experiencing problems is key to operate Kubernetes cluster effectively and efficiently.

In addition, we can use observability tools to make data-driven decisions.  For example, how effective is a particular piece of equipment?  How much of a certain product are we producing?  

Step 1: Setting Up Grafana and Prometheus for On-Premises Monitoring

Prometheus is an open-source tool that collects and stores metrics from a variety of sources in real-time.  Grafana is an open-source data analytics and visualization tool.  In this lab, you will deploy Prometheus and Grafana within your on-premises Arc-enabled Kubernetes cluster. Grafana will be configured to collect and display metrics from Prometheus, a popular monitoring tool for Kubernetes.

>[!knowledge] While there is an Azure-native solution, known as [Azure Managed Grafana](https://learn.microsoft.com/en-us/azure/managed-grafana/overview), this lab focuses on self-hosting this solution.

Install Prometheus and Grafana:

A common way to install these tools is with Helm and the open-source [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md).  

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

There are *lots* of different ways to configure this.  Inside VSCode, open artifacts/kube-prometheus-stack-values.yaml.

![Image of values.yaml file](../media/image/module3-values-yaml.png)

Inside the values file, there are many different parameters that we could set.  For example, line 1019 lists a value of **adminPassword: prom-operator**.  If we wanted to change this or any of the other default parameters, we could modify the values file.

>[!tip]Refer to [this section](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md#configuration) of the Helm repository to learn more about customizing this particular chart.

Deploy Prometheus to collect cluster metrics.

Install Grafana and configure it to pull metrics from Prometheus.

Create Dashboards:

Develop custom dashboards in Grafana to visualize CPU usage, memory utilization, pod health, and more.

Alerting:

Set up alerting rules in Grafana to notify administrators of any performance anomalies or threshold breaches.

Step 2: Leveraging Azure Monitor for Cloud-Based Insights

Azure Monitor provides a comprehensive solution for collecting, analyzing, and acting on telemetry data from your cloud and on-premises environments. For Arc-enabled Kubernetes clusters, Azure Monitor helps extend observability into the cloud, ensuring you have a centralized view of your cluster's health.

Enable Azure Arc Monitoring:

Connect your Arc-enabled Kubernetes cluster to Azure Monitor.

Configure Azure Monitor to collect and analyze logs and metrics from the cluster.

Insights and Analytics:

Utilize Azure Monitor Workbooks to create rich visualizations and analyses of your Kubernetes metrics.

Set up alerts and automated responses based on the telemetry data collected by Azure Monitor.

Health Monitoring:

Monitor the health of your Arc-enabled Kubernetes cluster from the Azure portal.

Use Azure Monitor’s machine learning algorithms to detect and predict issues before they impact your applications.

Conclusion

By integrating Grafana for on-premises observability and Azure Monitor for cloud-based insights, you can ensure comprehensive observability of your Arc-enabled Kubernetes clusters. This dual approach provides flexibility and depth, allowing you to maintain high standards of performance and reliability across diverse environments.

### Module 3.2 - GitOps

### Module 3.3 - Secure the infrastructure

## **Congratulations, you have reached the end of this lab.**

- Call to action
- Other sessions
- Jumpstart linksi