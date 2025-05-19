#!/bin/bash
set -euo pipefail

echo "✅ Validating detection registry..."

yq e 'length' detections/_registry.yaml > /dev/null

# Check each entry has required keys
for key in name tool category rule sim; do
  yq e ".[].$key" detections/_registry.yaml > /dev/null
done

echo "✅ Registry structure looks good."

# Optional: check sim scripts exist
while IFS= read -r sim; do
  if [ ! -f "$sim" ]; then
    echo "❌ Missing sim script: $sim"
    exit 1
  fi
done < <(yq e '.[].sim' detections/_registry.yaml)

echo "✅ All sim scripts found."