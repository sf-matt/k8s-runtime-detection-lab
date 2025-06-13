#!/bin/bash

POD_NAME=persistence-systemd-drop
POLICY=block-systemd-edit
NAMESPACE=default

echo "[*] Cleaning up any existing pod and policy..."
kubectl delete pod $POD_NAME -n $NAMESPACE --ignore-not-found
kubectl delete ksp $POLICY -n $NAMESPACE --ignore-not-found

echo "[*] Applying KubeArmor policy..."
kubectl apply -f rules/kubearmor/persistence/kubearmor-policy-block-systemd-edit.yaml
sleep 3

echo "[*] Launching test pod with access to /etc/systemd/system..."
kubectl run $POD_NAME \
  -n $NAMESPACE \
  --image=busybox \
  --labels=app=demo-kubearmor \
  --restart=Never \
  --overrides='
  {
    "spec": {
      "hostPID": true,
      "volumes": [
        {
          "name": "host-systemd",
          "hostPath": {
            "path": "/etc/systemd/system",
            "type": "Directory"
          }
        }
      ],
      "containers": [
        {
          "name": "demo-container",
          "image": "busybox",
          "securityContext": {
            "privileged": true
          },
          "command": ["sleep", "60"],
          "volumeMounts": [
            {
              "mountPath": "/mnt/systemd",
              "name": "host-systemd"
            }
          ]
        }
      ]
    }
  }'

echo "[*] Waiting for pod to be ready..."
kubectl wait --for=condition=Ready pod/$POD_NAME -n $NAMESPACE --timeout=20s

echo "[*] Attempting to write to /mnt/systemd/fakesvc.service (should be blocked)..."
kubectl exec -n $NAMESPACE $POD_NAME -- sh -c 'cat <<EOF > /mnt/systemd/fakesvc.service
[Unit]
Description=Sneaky Service
[Service]
ExecStart=/bin/bash -c "sleep infinity"
EOF' || echo "✅ Block confirmed."

echo "[*] Cleaning up..."
kubectl delete pod $POD_NAME -n $NAMESPACE --ignore-not-found
kubectl delete ksp $POLICY -n $NAMESPACE --ignore-not-found

echo "[*] Done."
