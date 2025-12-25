# Cluster Observability & Performance Monitoring

## Overview
This document outlines the observability stack implemented for the Microservices Platform. To ensure high availability and performance, I deployed a full-stack monitoring solution using **Prometheus** for metrics collection and **Grafana** for data visualization.



## 1. The Stack
- **Helm:** Used as the package manager to deploy the `kube-prometheus-stack`.
- **Prometheus:** Configured to scrape metrics from the cluster nodes and the 10+ microservices every 15 seconds.
- **Grafana:** Provides real-time dashboards for infrastructure and application-level metrics.
- **Node Exporter:** Installed on the cluster to track hardware-level metrics (CPU, RAM, Disk I/O).

## 2. Implementation Strategy

### Deployment via Helm
I utilized Helm to manage the lifecycle of the monitoring stack, ensuring all components (Alertmanager, Prometheus, Grafana) were deployed into a dedicated `monitoring` namespace for administrative isolation.

```bash
# Command used for deployment
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring