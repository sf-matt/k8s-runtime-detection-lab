#!/bin/bash
set -euo pipefail

echo "🔍 Checking rule paths and script permissions..."

# Check all rule files exist
while IFS= read -r rule; do
  if [ ! -f "$rule" ]; then
    echo "❌ Missing rule file: $rule"
    exit 1
  fi
done < <(yq e '.[].rule' detections/_registry.yaml)

# Check sim scripts exist and are executable
while IFS= read -r sim; do
  if [ ! -x "$sim" ]; then
    echo "❌ Simulation script not executable: $sim"
    exit 1
  fi
done < <(yq e '.[].sim' detections/_registry.yaml)

echo "✅ All rule paths valid and sim scripts executable."