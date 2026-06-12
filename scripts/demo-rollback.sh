#!/bin/bash
echo "====== DEMO ROLLBACK ======"

echo "--- Version actuelle ---"
kubectl get deployment sample-app-sample-app -n app \
  -o jsonpath='Image: {.spec.template.spec.containers[0].image}'
echo ""
kubectl get pods -n app

echo ""
echo "--- Deploiement version CASSEE ---"
helm upgrade sample-app ~/kubequest-app/charts/sample-app/ \
  --namespace app \
  --set image.tag="v-BROKEN-DOES-NOT-EXIST" \
  --wait --timeout 60s || echo "Echec attendu !"

sleep 10
echo ""
echo "--- Pods en erreur ---"
kubectl get pods -n app
kubectl describe pods -n app \
  -l app.kubernetes.io/name=sample-app \
  | grep -A3 "Events:" | head -20

echo ""
echo "--- ROLLBACK ---"
helm rollback sample-app --namespace app

echo "Attente stabilisation..."
kubectl rollout status \
  deployment/sample-app-sample-app -n app

echo ""
echo "--- App restauree ---"
kubectl get pods -n app
helm history sample-app -n app
