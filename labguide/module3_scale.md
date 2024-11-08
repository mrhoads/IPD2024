### Module 3.1 - Observability

Lab Scenario: Implementing Observability for Arc-enabled Kubernetes Clusters

In this lab, we'll explore how to observe the health and status of Arc-enabled Kubernetes clusters using Grafana and Azure Monitor. While there's overlap between these tools, we intend to show the core capabilities of both and discuss typical approaches used for monitoring.


## What do we mean by observability?

Observability in Kubernetes is crucial for maintaining the performance, reliability, and availability of applications. In industrial scenarios, this is crucial because the workloads being deployed are critical for worker safety, manufacturing, and a host of other reasons.  Knowing that a system is healthy or, conversely, knowing that a system is experiencing problems is key to operate Kubernetes cluster effectively and efficiently. #TODO - end here

Arc-enabled Kubernetes clusters provide a unified management platform for Kubernetes clusters across on-premises, multi-cloud, and edge environments. By integrating Grafana and Azure Monitor, you can achieve a holistic view of your cluster's performance and health metrics.

Step 1: Setting Up Grafana for On-Premises Monitoring

Grafana is an open-source platform for monitoring and observability, capable of visualizing metrics from various data sources. In this lab, you will deploy Grafana within your on-premises Arc-enabled Kubernetes cluster. Grafana will be configured to collect and display metrics from Prometheus, a popular monitoring tool for Kubernetes.

Install Prometheus and Grafana:

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