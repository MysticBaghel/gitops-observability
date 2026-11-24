# Documentation

Supporting documentation for the GitOps Observability project.

## Start here

- [Main README](../README.md): overview, quick start, screenshots, and limitations.
- [Setup and operations](setup.md): prerequisites, the `Makefile` shortcuts, applying rules, and local access.

## Architecture and operations

- [Architecture](architecture.md): system components, namespaces, and observability data flow.
- [Setup and operations](setup.md): cluster checks, applying alert rules, opening the UIs, and troubleshooting.
- [Alerting](alerting.md): custom Prometheus rules, the verified Inactive, Pending and Firing lifecycle, and limitations.

## Observability components

- [Monitoring](../monitoring/README.md): Prometheus metrics, Grafana dashboards, and alerting.
- [Logging](../logging/README.md): centralized log collection using Grafana Alloy and Loki.
- [LogQL queries](../logging/queries/logql-queries.md): ready-to-use Loki queries.
- [Tracing](../tracing/README.md): distributed tracing using OpenTelemetry and Jaeger, including OTLP configuration and trace verification.

## Quick reference

Run from the repository root. `make` lists every target.

| Task | Command |
|---|---|
| Start the cluster | `make up` |
| Check health | `make status` |
| Open Grafana, Prometheus and Jaeger | `make open` (stop with `make stop`) |
| Generate application traffic | `make traffic` |
| Apply alert rules | `make alerts` |

Default local URLs: Grafana `http://localhost:3000`, Prometheus `http://localhost:9090`, Jaeger `http://localhost:16686`.

## Screenshots

All evidence screenshots are in [`../screenshots/`](../screenshots/) and are embedded where they are discussed:

| Topic | Page |
|---|---|
| Dashboard, scrape targets, rule health | [Monitoring](../monitoring/README.md#evidence) |
| Alert Inactive, Pending, Firing | [Alerting](alerting.md#verified-alert-lifecycle) |
| Loki log exploration | [Logging](../logging/README.md#evidence) |
| Jaeger traces | [Tracing](../tracing/README.md#evidence) |
| All of the above plus Argo CD and cluster status | [Main README](../README.md#screenshots) |

Start with the [main project README](../README.md) for the project overview, architecture summary, and dashboard details.
