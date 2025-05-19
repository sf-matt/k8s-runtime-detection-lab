#!/bin/bash

KEYWORD="$1"

if [ -z "$KEYWORD" ]; then
  echo "Usage: $0 <keyword>"
  echo "Example: $0 TOCTOU"
  exit 1
fi

echo "[*] Searching Falco logs for: $KEYWORD"

for pod in $(kubectl get pods -n falco -l app.kubernetes.io/instance=falco -o name); do
  if kubectl logs -n falco "$pod" -c falco --tail=300 | grep -qi "$KEYWORD"; then
    echo "✅ Detection matched in $pod"
    echo "ℹ️  To inspect: kubectl logs -n falco $pod -c falco --tail=500"
    exit 0
  fi
done

echo "❌ Detection NOT found in any Falco pod"
echo "ℹ️  Run: kubectl logs -n falco -l app.kubernetes.io/instance=falco -c falco --tail=100"
exit 1