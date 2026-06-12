#!/bin/bash
set -e
echo "====== KubeQuest — Déploiement complet ======"

echo "--- Namespaces ---"
for ns in app monitoring logging ingress-nginx argocd kubernetes-dashboard; do
  kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f -
done

echo "--- nginx-ingress (node: ingress) ---"
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --values /tmp/ingress-values.yaml \
  --wait --timeout 5m
echo "nginx-ingress OK"

echo "--- kube-prometheus (node: monitoring) ---"
helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values /tmp/prometheus-values.yaml \
  --wait --timeout 10m
echo "Prometheus OK"

echo "--- Loki (node: monitoring) ---"
helm upgrade --install loki grafana/loki-stack \
  --namespace logging \
  --values /tmp/loki-values.yaml \
  --wait --timeout 5m
echo "Loki OK"

echo "--- Secrets app ---"
kubectl create secret generic sample-app-secrets \
  --namespace app \
  --from-literal=APP_KEY="base64:DJYTvaRkEZ/YcQsX3TMpB0iCjgme2rhlIOus9A1hnj4=" \
  --from-literal=DB_HOST="sample-app-mysql" \
  --from-literal=DB_USERNAME="app_user" \
  --from-literal=DB_PASSWORD="StrongPass123!" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic mysql-credentials \
  --namespace app \
  --from-literal=mysql-password="StrongPass123!" \
  --from-literal=mysql-root-password="RootStrongPass456!" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "--- Application Laravel (nodes: kube-1 + kube-2) ---"
cd ~/kubequest-app
helm dependency update charts/sample-app/ --quiet
helm upgrade --install sample-app charts/sample-app/ \
  --namespace app \
  --wait --timeout 10m
echo "App OK"

echo "====== DONE ======"
kubectl get nodes
kubectl get pods -A -o wide
