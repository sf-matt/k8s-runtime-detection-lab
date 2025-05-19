#!/bin/bash

REGISTRY=./detections/_registry.yaml

echo "[*] Validating KubeArmor policies in registry..."

# Loop over all KubeArmor detections with validation enabled
yq eval '.[] | select(.tool == "kubearmor") | select(.validate == true) | [.name, .log_match] | @tsv' "$REGISTRY" |
while IFS=$'\t' read -r NAME LOG_MATCH; do
  if [ -z "$LOG_MATCH" ]; then
    echo "❌ No log_match string provided for $NAME"
    continue
  fi

  MATCH_FOUND=$(kubectl logs -n kubearmor -l kubearmor-app=kubearmor --tail=1000 2>/dev/null | grep -F "$LOG_MATCH")

  if [ -n "$MATCH_FOUND" ]; then
    echo "✅ Detection found for: $NAME"
  else
    echo "❌ Detection not found for: $NAME"
  fi
done
