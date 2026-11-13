# Distributed Tracing

## Overview

This component of the Kubernetes-based GitOps Observability Lab implements distributed tracing using OpenTelemetry and Jaeger.

The objective is to instrument the FastAPI application, collect distributed traces through the OpenTelemetry Protocol (OTLP), and visualize request execution and span information through the Jaeger UI.

## Architecture

```text
FastAPI Application
 (2 Kubernetes Replicas)
         |
         | OpenTelemetry SDK
         v
    OTLP Exporter
         |
         | HTTP / 4318
         v
       Jaeger
  (Trace Collection
   and Storage)
         |
         v
     Jaeger UI
  (Trace Exploration)
```

## Technology Stack

| Component | Purpose |
|---|---|
| OpenTelemetry | Application instrumentation and telemetry |
| OTLP | Trace transmission protocol |
| Jaeger | Trace collection, storage and visualization |
| Helm | Deployment and configuration |
| Kubernetes | Container orchestration |
| Minikube | Local Kubernetes environment |

## Deployment Details

| Component | Helm Release | Namespace | Version |
|---|---|---|---|
| Jaeger | jaeger | monitoring | Chart 4.16.1 |
 
Jaeger runs as a single-replica deployment using in-memory trace storage.

OTLP receivers are exposed through:
- gRPC: `4317`
- HTTP: `4318`

Jaeger UI is exposed on port `16686`.

## Directory Structure

```text
tracing/
├── README.md
└── jaeger/
    └── values.yaml
```

## 1. Jaeger Deployment

Jaeger is deployed using the Jaeger Helm chart.

### Add Helm Repository

```bash
helm repo add jaegertracing \
  https://jaegertracing.github.io/helm-charts

helm repo update
```

### Install Jaeger

```bash
helm upgrade --install jaeger jaegertracing/jaeger \
  --version 4.16.1 \
  --namespace monitoring \
  --create-namespace \
  -f tracing/jaeger/values.yaml \
  --wait --timeout 5m
```

### Verify Deployment

```bash
kubectl get pods -n monitoring | grep jaeger
kubectl get svc -n monitoring | grep jaeger
```

## 2. FastAPI OpenTelemetry Instrumentation

The FastAPI application uses OpenTelemetry instrumentation to automatically generate traces for incoming HTTP requests.

The following packages are included in `requirements.txt`:

```text
opentelemetry-distro[otlp]
opentelemetry-instrumentation-fastapi
```

The application Dockerfile starts FastAPI using the OpenTelemetry instrumentation launcher:

```dockerfile
CMD ["opentelemetry-instrument", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## 3. OTLP Configuration

The Kubernetes Deployment configures the application to export traces to Jaeger.

Environment variables:

| Variable | Value |
|---|---|
| `OTEL_SERVICE_NAME` | `gitops-demo` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://jaeger.monitoring.svc.cluster.local:4318` |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `http/protobuf` |
| `OTEL_TRACES_EXPORTER` | `otlp` |
| `OTEL_METRICS_EXPORTER` | `none` |
| `OTEL_LOGS_EXPORTER` | `none` |

The application sends traces to Jaeger's OTLP HTTP receiver through the Kubernetes service endpoint.

## 4. Access Jaeger UI

Forward the Jaeger query service:

```bash
kubectl port-forward -n monitoring \
  svc/jaeger 16686:16686
```

Open:

```text
http://localhost:16686
```

Select `gitops-demo` from the Service dropdown and click **Find Traces**.

## 5. Generate Application Traces

Forward the FastAPI application service:

```bash
kubectl port-forward -n gitops-demo \
  svc/<application-service-name> 8000:8000
```

Generate HTTP requests:

```bash
for i in {1..20}; do
  curl -s http://localhost:8000/
  curl -s http://localhost:8000/health
  sleep 1
done
```

Return to Jaeger and search for the generated traces.

## 6. Verification Results

The tracing pipeline was successfully verified.

- Jaeger deployed successfully in the monitoring namespace.
- FastAPI instrumentation configured using OpenTelemetry.
- OTLP HTTP receiver configured on port `4318`.
- Kubernetes Deployment updated with OpenTelemetry environment variables.
- GitHub Actions successfully built and pushed the instrumented application image.
- ArgoCD synchronized the updated deployment.
- Jaeger discovered the `gitops-demo` service.
- Application traces and HTTP operation spans appeared in the Jaeger UI.
- Multiple traces were successfully collected and inspected.

## 7. Troubleshooting

### Jaeger pod not running

```bash
kubectl get pods -n monitoring | grep jaeger
kubectl logs deployment/jaeger -n monitoring --tail=100
```

### Application not exporting traces

```bash
kubectl logs deployment/gitops-demo \
  -n gitops-demo --tail=100
```

Check the OpenTelemetry environment variables:

```bash
kubectl get deployment gitops-demo \
  -n gitops-demo -o yaml | grep -A2 OTEL_
```

### Verify Jaeger services

```bash
kubectl get svc -n monitoring | grep jaeger
```

### Check Helm release

```bash
helm list -n monitoring
```

**Note:** Jaeger currently uses in-memory storage. Traces are ephemeral and can be lost when the Jaeger pod restarts.