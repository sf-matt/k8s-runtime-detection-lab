#!/bin/bash

POD_NAME=rbac-toctou-configmap-detect
CONFIG_MAP=dummy-config

echo "[*] Deleting old simulation if it exists..."
kubectl delete pod $POD_NAME --ignore-not-found
kubectl delete cm $CONFIG_MAP --ignore-not-found

echo "[*] Creating dummy ConfigMap..."
kubectl create configmap $CONFIG_MAP --from-literal=entry="test" --dry-run=client -o yaml | kubectl apply -f -

echo "[*] Launching new pod with /mnt/configmap mount..."
kubectl run $POD_NAME \
  --image=busybox \
  --restart=Never \
  --labels=app=demo-falco \
  --overrides='
{
  "apiVersion": "v1",
  "spec": {
    "containers": [{
      "name": "demo",
      "image": "busybox",
      "command": ["sh", "-c", "sleep 60"],
      "volumeMounts": [{
        "name": "cfg",
        "mountPath": "/mnt/configmap"
      }]
    }],
    "volumes": [{
      "name": "cfg",
      "configMap": {
        "name": "dummy-config"
      }
    }]
  }
}' \
  --command

echo "[*] Waiting for pod to become ready..."
kubectl wait --for=condition=Ready pod/$POD_NAME --timeout=30s

echo "[*] Executing write to /mnt/configmap/entry..."
kubectl exec $POD_NAME -- sh -c 'echo hacked > /mnt/configmap/entry'

echo "[*] Cleaning up..."
kubectl delete pod $POD_NAME --ignore-not-found
kubectl delete configmap $CONFIG_MAP --ignore-not-found

echo "[*] Done."