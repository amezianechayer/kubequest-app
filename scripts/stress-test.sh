#!/bin/bash
INGRESS_IP=$(kubectl get node ingress \
  -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

echo "====== STRESS TEST ======"
echo "Target : http://$INGRESS_IP:30080"
echo ""
echo "HPA avant :"
kubectl get hpa -n app
echo ""
echo "Envoi de 3000 requetes en parallele..."

for i in $(seq 1 3000); do
  curl -s -o /dev/null \
    -H "Host: app.kubequest.local" \
    "http://$INGRESS_IP:30080/" &
  if (( i % 300 == 0 )); then
    echo "--- $i requetes ---"
    kubectl get hpa -n app --no-headers
  fi
done
wait

echo ""
echo "HPA apres (le scaling peut prendre 1-2 min) :"
kubectl get hpa -n app
kubectl get pods -n app -o wide
