#!/bin/bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kedacore https://kedacore.github.io/charts

helm repo update

# Install Prometheus
helm install prometheus prometheus-community/prometheus \
  --namespace prometheus \
  --create-namespace

# Install Keda
helm install keda kedacore/keda \
  --namespace keda \
  --create-namespace
