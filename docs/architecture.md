# Architecture

## Overview

This repository contains monitoring configuration for a separate FastAPI application deployed to Kubernetes.

- `gitops-app` contains the FastAPI app, Docker build, Kubernetes application manifests, and GitHub Actions workflow.
- `gitops-observability` contains monitoring configuration and custom Prometheus alert rules.

## Namespaces

| Namespace | Workloads |
|---|---|
| `gitops-demo` | FastAPI Deployment, Pods, Service, and ServiceMonitor |
| `monitoring` | Prometheus stack, Grafana, and custom PrometheusRule |

## Metrics flow

1. FastAPI exposes metrics at `/metrics` using `prometheus-fastapi-instrumentator`.
2. A Kubernetes Service provides a stable endpoint for the application Pods.
3. A `ServiceMonitor` selects the application Service and configures the scrape endpoint.
4. Prometheus discovers the `ServiceMonitor` and scrapes application metrics.
5. Grafana queries Prometheus to render the application dashboard.
6. Prometheus evaluates the custom rules in `alerts/app-alerts.yaml`.

## Components

- **Prometheus:** metrics collection, storage, PromQL queries, and alert evaluation.
- **Prometheus Operator:** manages Prometheus custom resources.
- **ServiceMonitor:** describes how Prometheus discovers and scrapes the application Service.
- **PrometheusRule:** declares alerting rules.
- **Grafana:** presents metrics through dashboards.
- **kube-state-metrics:** exposes Kubernetes resource state.
- **node-exporter:** exposes node-level metrics.

## Responsibility boundary

GitHub Actions and Argo CD belong to the application delivery workflow in the companion `gitops-app` repository. This repository does not build the FastAPI container image.

The monitoring stack was installed with Helm. Applying the custom `PrometheusRule` is a Kubernetes operation. Full GitOps reconciliation of this repository through Argo CD is a possible future enhancement, not an implemented feature to assume.
