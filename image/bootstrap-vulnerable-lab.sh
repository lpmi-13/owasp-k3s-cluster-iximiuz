#!/bin/bash
set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-/home/laborant/.kube/config}"
CRD_PATH="/opt/vulnerable-lab-operator/lab.security.lab_vulnerablelabs.yaml"

export KUBECONFIG="${KUBECONFIG_PATH}"

for _ in $(seq 1 90); do
  if kubectl get --raw=/readyz >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

kubectl get --raw=/readyz >/dev/null 2>&1 || {
  echo "k3s API did not become ready in time"
  exit 1
}

kubectl apply -f "${CRD_PATH}"
kubectl wait --for=condition=Established --timeout=60s \
  crd/vulnerablelabs.lab.security.lab
