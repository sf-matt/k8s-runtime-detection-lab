#!/bin/bash

REGISTRY=./detections/_registry.yaml

echo "[*] Validating Falco rules in registry..."

# Use yq to loop over each entry
yq eval '.[] | select(.tool == "falco") | select(.validate == true) | [.name, .log_match] | @tsv' "$REGISTRY" |
while IFS=$'\t' read -r NAME LOG_MATCH; do
  if [ -z "$LOG_MATCH" ]; then
    echo "❌ No log_match string provided for $NAME"
    continue
  fi

  MATCH_FOUND=$(kubectl logs -n falco -l app.kubernetes.io/instance=falco --tail=1000 2>/dev/null | grep -F "$LOG_MATCH")

  if [ -n "$MATCH_FOUND" ]; then
    echo "✅ Detection found for: $NAME"
  else
    echo "❌ Detection not found for: $NAME"
  fi
done