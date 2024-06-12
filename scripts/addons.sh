#!/bin/bash

REDIS="${REDIS:-false}"
MYSQL="${MYSQL:-false}"

while [ $# -gt 0 ]; do
  case $1 in
    -r | --redis)
      REDIS="true"
      ;;
    -m | --mysql)
      MYSQL="true"
      ;;
  esac
  shift
done

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

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: databases
  labels:
    name: databases
EOF

# Install MySQL
if [ "$MYSQL" == "true" ]; then
cat <<EOF | kubectl apply --namespace databases -f -
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  ports:
  - port: 3306
  selector:
    app: mysql
  clusterIP: None
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - image: mysql:lts
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: password
        ports:
        - containerPort: 3306
          name: mysql
EOF
fi

# Install Redis
if [ "$REDIS" == "true" ]; then
cat <<EOF | kubectl apply --namespace databases  -f -
apiVersion: v1
kind: Service
metadata:
  name: redis
spec:
  ports:
  - port: 6379
  selector:
    app: redis
  clusterIP: None
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  selector:
    matchLabels:
      app: redis
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - image: redis:7-alpine
        name: redis
        ports:
        - containerPort: 6379
          name: redis
EOF
fi
