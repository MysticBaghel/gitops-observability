# Monitoring

## Overview

This component of the Kubernetes-based GitOps Observability Lab implements metrics monitoring using Prometheus and Grafana.

The objective is to collect application and Kubernetes metrics, evaluate alerting rules, and visualize system health through Grafana dashboards.

## Architecture

```text
FastAPI Application
 (2 Kubernetes Replicas)
         |
         | /metrics
         v
    Prometheus
 (Metrics Collection)
         |
         v
      Grafana
 (Dashboards / Queries)

PrometheusRule
      |
      v
 Prometheus
 (Alert Evaluation)
```

## Technology Stack

| Component | Purpose |
|---|---|
| Prometheus | Metrics collection and storage |
| Grafana | Metrics visualization and dashboards |
| kube-prometheus-stack | Helm chart for monitoring components |
| Prometheus Operator | Manages Prometheus resources |
| ServiceMonitor | Configures application metrics scraping |
| PrometheusRule | Defines custom alerting rules |
| Kubernetes | Container orchestration |
| Minikube | Local Kubernetes environment |

## Deployment Details

| Component | Helm Release | Namespace | Version |
|---|---|---|---|
| kube-prometheus-stack | kube-prometheus-stack | monitoring | Chart 92.21.2 |

Prometheus and Grafana are deployed through the kube-prometheus-stack Helm chart.

The FastAPI application exposes metrics through its `/metrics` endpoint.

## Directory Structure

```text
monitoring/
├── README.md
├── values.yaml
├── kube-prometheus-stack-92.21.2.tgz
└── kube-prometheus-stack/
```

## 1. Prometheus and Grafana Deployment

The kube-prometheus-stack Helm chart is used to deploy the monitoring stack.

### Add Helm Repository

```bash
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts

helm repo update
```

### Install Monitoring Stack

```bash
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --version 92.21.2 \
  --namespace monitoring \
  --create-namespace \
  -f monitoring/values.yaml \
  --wait --timeout 10m
```

### Verify Deployment

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get prometheus -n monitoring
```

## 2. Application Metrics

The FastAPI application uses `prometheus-fastapi-instrumentator` to expose application metrics.

Metrics endpoint:

```text
/metrics
```

Prometheus discovers the application through a Kubernetes ServiceMonitor.

### Verify Metrics Endpoint

```bash
kubectl port-forward -n gitops-demo \
  deployment/gitops-demo 8000:8000
```

In another terminal:

```bash
curl http://localhost:8000/metrics
```

The endpoint exposes Prometheus-formatted application metrics, including HTTP request metrics.

## 3. ServiceMonitor

The ServiceMonitor configures Prometheus to scrape metrics from the FastAPI application.

Verify the resource:

```bash
kubectl get servicemonitor -A
```

Inspect the application ServiceMonitor:

```bash
kubectl describe servicemonitor -n gitops-demo
```

## 4. Grafana Access

Forward the Grafana service:

```bash
kubectl port-forward -n monitoring \
  svc/kube-prometheus-stack-grafana 3000:80
```

Open Grafana:

```text
http://localhost:3000
```

Use the configured Grafana credentials to log in.

Prometheus is configured as a datasource through the kube-prometheus-stack deployment.

## 5. Prometheus Queries

Open Prometheus or Grafana Explore and execute PromQL queries.

### Total HTTP Requests

```promql
sum(rate(http_requests_total[5m]))
```

### HTTP Requests by Status

```promql
sum by (status) (rate(http_requests_total[5m]))
```

### Pod CPU Usage

```promql
sum by (pod) (
  rate(container_cpu_usage_seconds_total[5m])
)
```

### Pod Memory Usage

```promql
sum by (pod) (
  container_memory_working_set_bytes
)
```

## 6. Alerting

Custom alerting rules are defined using PrometheusRule resources.

The alert configuration is maintained in:

```text
alerts/app-alerts.yaml
```

The rules are applied using:

```bash
kubectl apply -f alerts/app-alerts.yaml
```

Verify alert rules:

```bash
kubectl get prometheusrule -A
```

Inspect the configured rules:

```bash
kubectl describe prometheusrule -n gitops-demo
```

Additional alerting documentation is available in [Alerting](../docs/alerting.md).

## 7. Verification Results

The monitoring setup was verified through the following checks:

- Prometheus and Grafana pods running in the monitoring namespace.
- FastAPI `/metrics` endpoint exposing application metrics.
- ServiceMonitor configured for application metrics scraping.
- Prometheus collecting application metrics.
- Grafana dashboards displaying monitoring data.
- Custom PrometheusRule resources deployed.

## 8. Troubleshooting

### Prometheus not scraping application metrics

```bash
kubectl get servicemonitor -A
kubectl get svc -n gitops-demo
kubectl get endpoints -n gitops-demo
```

Check Prometheus targets through its UI.

### Grafana unavailable

```bash
kubectl get pods -n monitoring | grep grafana
kubectl get svc -n monitoring | grep grafana
```

### Check Helm release

```bash
helm list -n monitoring
```

### Inspect Prometheus logs

```bash
kubectl get pods -n monitoring | grep prometheus
```

Use the Prometheus pod name to inspect logs:

```bash
kubectl logs <prometheus-pod-name> -n monitoring --tail=100
```