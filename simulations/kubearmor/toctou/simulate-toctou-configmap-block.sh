#!/bin/bash

POD_NAME=toctou-configmap-write-block
POLICY=toctou-configmap-write-block

echo "[*] Cleaning up any existing pod and policy..."
kubectl delete pod $POD_NAME --ignore-not-found
kubectl delete ksp $POLICY -n default --ignore-not-found

echo "[*] Applying KubeArmor policy..."
kubectl apply -f rules/kubearmor/toctou/toctou-configmap-block.yaml
sleep 3

echo "[*] Launching test pod with writable /mnt/configmap..."
kubectl run $POD_NAME \
  --image=busybox \
  --labels=app=demo-kubearmor \
  --restart=Never \
  --overrides='
  {
    "spec": {
      "volumes": [
        {
          "name": "configmap-volume",
          "emptyDir": {}
        }
      ],
      "containers": [
        {
          "name": "demo-container",
          "image": "busybox",
          "command": ["sleep", "60"],
          "volumeMounts": [
            {
              "mountPath": "/mnt/configmap",
              "name": "configmap-volume"
            }
          ]
        }
      ]
    }
  }'

echo "[*] Waiting for pod to be ready..."
kubectl wait --for=condition=Ready pod/$POD_NAME --timeout=20s

echo "[*] Attempting to write to /mnt/configmap/test (should be blocked)..."
kubectl exec $POD_NAME -- sh -c 'echo blocked > /mnt/configmap/test' || echo "✅ Block confirmed."

echo "[*] Cleaning up..."
kubectl delete pod $POD_NAME --ignore-not-found
kubectl delete ksp $POLICY -n default --ignore-not-found

echo "[*] Done."