# Setup and Operations

This guide documents the known local workflow. It assumes the Kubernetes cluster and `kube-prometheus-stack` installation already exist.

## Shortcut: Makefile

The repository root has a `Makefile` that wraps the commands in this guide. Run `make` to list targets.

| Command | Does |
|---|---|
| `make up` | Start Minikube |
| `make status` | Pods in `gitops-demo` and `monitoring`, plus Helm releases |
| `make open` | Background port-forwards for Grafana (3000), Prometheus (9090), Jaeger (16686) |
| `make stop` | Stop those port-forwards |
| `make traffic` | Send 20 requests to `/` and `/health` |
| `make alerts` | Apply `alerts/app-alerts.yaml` |
| `make logs-app` / `make logs-alloy` | Tail application or Alloy logs |
| `make install` | Fresh-cluster Helm install of the whole stack |

Requires GNU `make` (`sudo dnf install make` on Fedora).

## Prerequisites

- Minikube or another Kubernetes cluster
- `kubectl`
- Helm 3
- `kube-prometheus-stack` installed in namespace `monitoring`
- FastAPI application deployed in namespace `gitops-demo`
- Application metrics exposed at `/metrics`
- Matching Service and `ServiceMonitor`

## Check cluster state

```bash
minikube status
kubectl get pods -A
kubectl get deployments -A
kubectl get pods -n gitops-demo -o wide
kubectl get pods -n monitoring
kubectl get prometheus -n monitoring
kubectl get servicemonitor -A
```

## Apply custom alert rules

From the repository root:

```bash
kubectl apply -f alerts/app-alerts.yaml
kubectl get prometheusrule gitops-demo-alerts -n monitoring
```

Prometheus is configured to select rules with the label `release: monitoring`. The custom rule manifest includes that label and is in namespace `monitoring`.

## Open Prometheus

Run and leave this process running:

```bash
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
```

Visit `http://localhost:9090`. Useful pages:

- `/targets` — scrape target health
- `/alerts` — current alert states
- `/rules` — rule evaluation health

## Open Grafana

In a second terminal, run:

```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```

Visit `http://localhost:3000` and open the `GitOps Application Monitoring` dashboard.

Stop a port-forward with `Ctrl+C`. If a local port is already in use, an existing port-forward may still be running in another terminal.

## Useful PromQL

Application scrape health:

```promql
up{namespace="gitops-demo"}
```

HTTP request rate:

```promql
sum(rate(http_requests_total{namespace="gitops-demo"}[5m]))
```

HTTP error rate:

```promql
sum(rate(http_requests_total{namespace="gitops-demo",status=~"4xx|5xx"}[5m]))
```

Ready application Pods:

```promql
sum(kube_pod_status_ready{namespace="gitops-demo",condition="true"})
```

Total instrumented requests:

```promql
sum(http_requests_total{namespace="gitops-demo"})
```

The total request counter may include `/metrics` scrape traffic.

## Troubleshooting

### Grafana shows no data

- Check the dashboard time range.
- Confirm the Prometheus data source is selected.
- Check Prometheus Targets and verify application targets are `UP`.
- Test the PromQL expression directly in Prometheus.

### Prometheus does not show a custom rule

- Confirm the `PrometheusRule` exists in namespace `monitoring`.
- Confirm it has label `release: monitoring`.
- Check the Prometheus rule and namespace selectors.
- Inspect the Prometheus Rules page for evaluation errors.
