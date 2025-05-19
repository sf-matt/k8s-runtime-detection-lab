#!/bin/bash

POD_NAME=aws-credential-access-block
POLICY=aws-credential-access-block

echo "[*] Cleaning up any existing pod and policy..."
kubectl delete pod $POD_NAME --ignore-not-found
kubectl delete ksp $POLICY -n default --ignore-not-found

echo "[*] Applying KubeArmor policy..."
kubectl apply -f rules/kubearmor/creds/aws-credential-access-block.yaml
sleep 3

echo "[*] Launching test pod with fake AWS credentials..."
kubectl run $POD_NAME \
  --image=busybox \
  --labels=app=demo-kubearmor \
  --restart=Never \
  --overrides='
  {
    "spec": {
      "containers": [
        {
          "name": "demo-container",
          "image": "busybox",
          "command": ["sleep", "60"],
          "volumeMounts": [
            {
              "mountPath": "/root/.aws",
              "name": "aws-creds"
            }
          ]
        }
      ],
      "volumes": [
        {
          "name": "aws-creds",
          "emptyDir": {}
        }
      ]
    }
  }'

echo "[*] Waiting for pod to be ready..."
kubectl wait --for=condition=Ready pod/$POD_NAME --timeout=20s

echo "[*] Attempting to access /root/.aws/credentials (should be blocked)..."
kubectl exec $POD_NAME -- sh -c 'touch /root/.aws/credentials' || echo "✅ Block confirmed."

echo "[*] Cleaning up..."
kubectl delete pod $POD_NAME --ignore-not-found
kubectl delete ksp $POLICY -n default --ignore-not-found

echo "[*] Done."