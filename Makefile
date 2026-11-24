# Put this file in the ROOT of gitops-observability/ (next to README.md).
# Usage: `make` (shows help)   |   `make open`   |   `make status`
.RECIPEPREFIX = >
.DEFAULT_GOAL := help
SHELL := /bin/bash

NS      := monitoring
APP_NS  := gitops-demo
RELEASE := monitoring
PF_DIR  := .pf

help: ## show this list
> @grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n",$$1,$$2}'

# ---------- cluster ----------
up: ## start minikube (do this first after a reboot)
> minikube start
> kubectl get pods -A

status: ## cluster + app + monitoring health at a glance
> minikube status
> @echo "--- $(APP_NS)"; kubectl get pods -n $(APP_NS)
> @echo "--- $(NS)"; kubectl get pods -n $(NS)
> @echo "--- helm"; helm list -n $(NS)

# ---------- UIs ----------
open: stop ## port-forward Grafana, Prometheus, Jaeger in background
> @mkdir -p $(PF_DIR)
> @nohup kubectl port-forward -n $(NS) svc/$(RELEASE)-grafana 3000:80 >$(PF_DIR)/grafana.log 2>&1 & echo $$! >$(PF_DIR)/grafana.pid
> @nohup kubectl port-forward -n $(NS) svc/$(RELEASE)-kube-prometheus-prometheus 9090:9090 >$(PF_DIR)/prom.log 2>&1 & echo $$! >$(PF_DIR)/prom.pid
> @nohup kubectl port-forward -n $(NS) svc/jaeger 16686:16686 >$(PF_DIR)/jaeger.log 2>&1 & echo $$! >$(PF_DIR)/jaeger.pid
> @sleep 2
> @echo "Grafana    http://localhost:3000   (admin / admin123)"
> @echo "Prometheus http://localhost:9090"
> @echo "Jaeger     http://localhost:16686"

stop: ## kill all background port-forwards
> @for f in $(PF_DIR)/*.pid; do [ -f "$$f" ] && kill $$(cat $$f) 2>/dev/null; rm -f $$f; done; true

# ---------- app traffic ----------
traffic: ## send 20 requests to the app so metrics/logs/traces show up
> @kubectl port-forward -n $(APP_NS) deployment/gitops-demo 8000:8000 >/dev/null 2>&1 & PF=$$!; sleep 3; \
> for i in $$(seq 1 20); do curl -s localhost:8000/ >/dev/null; curl -s localhost:8000/health >/dev/null; sleep 1; done; \
> kill $$PF; echo "done - check Grafana, Loki (Explore) and Jaeger"

# ---------- alerts / logs ----------
alerts: ## apply the custom alert rules
> kubectl apply -f alerts/app-alerts.yaml
> kubectl get prometheusrule -n $(NS)

logs-app: ## tail the FastAPI app logs
> kubectl logs deployment/gitops-demo -n $(APP_NS) --tail=100 -f

logs-alloy: ## tail Alloy (log collector) logs
> kubectl logs deployment/alloy -n $(NS) --tail=100

# ---------- first-time install (only on a fresh cluster) ----------
install: ## install Prometheus/Grafana + Loki + Alloy + Jaeger via Helm
> helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
> helm repo add grafana https://grafana.github.io/helm-charts
> helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
> helm repo update
> helm upgrade --install $(RELEASE) prometheus-community/kube-prometheus-stack --version 92.21.2 -n $(NS) --create-namespace -f monitoring/values.yaml --wait --timeout 10m
> helm upgrade --install loki grafana/loki --version 7.6.0 -n $(NS) -f logging/loki/values.yaml --wait --timeout 5m
> helm upgrade --install alloy grafana/alloy --version 1.15.0 -n $(NS) -f logging/alloy/values.yaml --wait --timeout 5m
> helm upgrade --install jaeger jaegertracing/jaeger --version 4.16.1 -n $(NS) -f tracing/jaeger/values.yaml --wait --timeout 5m
> $(MAKE) alerts

.PHONY: help up status open stop traffic alerts logs-app logs-alloy install
