#!/bin/bash

MODULE=$1
RULES_DIR="rules/falco"

# Dynamically get available modules
AVAILABLE_MODULES=$(find "$RULES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
MODULE_LIST=$(echo "$AVAILABLE_MODULES" | tr '\n' ' ')

if [ -z "$MODULE" ]; then
  echo "❌ Usage: $0 <module-name | all>"
  echo "Available modules: $MODULE_LIST all"
  exit 1
fi

if [ "$MODULE" = "all" ]; then
  echo "[*] Merging all Falco rules across all modules..."
  find "$RULES_DIR" -name "*.yaml" -exec sh -c 'printf "\n---\n"; cat "$1"' _ {} \; > .falco-all-rules.yaml
  TARGET_FILE=".falco-all-rules.yaml"
else
  RULE_DIR="$RULES_DIR/$MODULE"

  if [ ! -d "$RULE_DIR" ]; then
    echo "❌ No such module directory: $RULE_DIR"
    echo "Available modules: $MODULE_LIST"
    exit 1
  fi

  echo "[*] Merging rules for module '$MODULE'..."
  find "$RULE_DIR" -name "*.yaml" -exec sh -c 'printf "\n---\n"; cat "$1"' _ {} \; > ".falco-${MODULE}-rules.yaml"
  TARGET_FILE=".falco-${MODULE}-rules.yaml"
fi

echo "[*] Upgrading Falco..."
if helm upgrade falco falcosecurity/falco -n falco --set-file customRules.customRules="$TARGET_FILE" > /dev/null 2>&1
then
  echo "✅ Falco rules for '$MODULE' deployed successfully."
  echo "[*] Waiting for Falco pods to be ready..."
  kubectl rollout status daemonset falco -n falco
else
  echo "❌ Failed to upgrade Falco. Check your Helm deployment."
  exit 1
fi
