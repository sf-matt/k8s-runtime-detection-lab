#!/bin/bash
set -euo pipefail

echo "=== Runtime Detection Scaffold ==="
read -p "Tool (falco/kubearmor): " TOOL
read -p "Category (e.g. rbac, creds, toctou): " CATEGORY
read -p "Rule/Detection name (e.g. aws-credential-access-block): " RULE_NAME

BRANCH_NAME="feature/${RULE_NAME}"
echo "[*] Creating and checking out branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

echo "[*] Creating folders..."
mkdir -p rules/${TOOL}/${CATEGORY}
mkdir -p simulations/${TOOL}/${CATEGORY}

RULE_FILE="rules/${TOOL}/${CATEGORY}/${RULE_NAME}.yaml"
SIM_FILE="simulations/${TOOL}/${CATEGORY}/simulate-${RULE_NAME}.sh"

echo "[*] Creating placeholder files..."
touch "$RULE_FILE"
touch "$SIM_FILE"
chmod +x "$SIM_FILE"

echo "[*] Detection stub created:"
echo "  Rule: $RULE_FILE"
echo "  Sim:  $SIM_FILE"
echo "✅ Done. Remember to update detections/_registry.yaml"