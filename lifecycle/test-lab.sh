#!/bin/bash

REGISTRY_FILE="detections/_registry.yaml"
TMP_FILTERED=".filtered-entries.yaml"

if ! [ -f "$REGISTRY_FILE" ]; then
  echo "❌ Registry file not found: $REGISTRY_FILE"
  exit 1
fi

if ! command -v yq &> /dev/null; then
  echo "❌ 'yq' is required for this script. Install it from https://github.com/mikefarah/yq/"
  exit 1
fi

CATEGORY_FILTER=""
AUTO_MODE=false
INCLUDE_K8SAUDIT=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --category=*)
      CATEGORY_FILTER="${1#*=}"
      shift
      ;;
    --auto)
      AUTO_MODE=true
      shift
      ;;
    --include-k8saudit)
      INCLUDE_K8SAUDIT=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Filter once, output as structured YAML
if [ "$INCLUDE_K8SAUDIT" = false ]; then
  yq e '.[] | select(.tool != "k8saudit")' "$REGISTRY_FILE" > "$TMP_FILTERED"
else
  yq e '.[]' "$REGISTRY_FILE" > "$TMP_FILTERED"
fi

if [ ! -s "$TMP_FILTERED" ]; then
  echo "❌ No detections found in registry."
  exit 1
fi

function validate_logs() {
  local KEYWORD="$1"
  if [[ -n "$KEYWORD" ]]; then
    echo "[*] Checking logs for: $KEYWORD"
    ./lifecycle/check-falco-logs.sh "$KEYWORD"
  fi
}

function wait_for_falco() {
  echo "[*] Waiting for Falco daemonset to be ready..."
  kubectl rollout status daemonset falco -n falco || { echo "❌ Falco not ready"; exit 1; }
}

if [ "$AUTO_MODE" = true ]; then
  echo "🔁 Running all detections in auto mode..."
  echo

  COUNT=$(yq e 'length' "$TMP_FILTERED")
  for ((i=0; i<COUNT; i++)); do
    NAME=$(yq e ".[$i].name" "$TMP_FILTERED")
    TOOL=$(yq e ".[$i].tool" "$TMP_FILTERED")
    SIM_SCRIPT=$(yq e ".[$i].sim" "$TMP_FILTERED")
    VALIDATE=$(yq e ".[$i].validate" "$TMP_FILTERED")
    LOG_MATCH=$(yq e ".[$i].log_match // """ "$TMP_FILTERED")

    echo "▶️  [$NAME] Running: $SIM_SCRIPT"
    if [ -x "$SIM_SCRIPT" ]; then
      [[ "$TOOL" == "falco" ]] && wait_for_falco
      bash "$SIM_SCRIPT"
      if [[ "$TOOL" == "falco" && "$VALIDATE" == "true" ]]; then
        validate_logs "$LOG_MATCH"
      fi
    else
      echo "❌ Script not found or not executable: $SIM_SCRIPT"
    fi
    echo
  done

  echo "✅ Auto run complete."
  rm -f "$TMP_FILTERED"
  exit 0
fi

while true; do
  clear
  echo "🧪 Runtime Detection Lab"
  echo "========================"
  echo

  declare -A INDEX_MAP
  i=1

  mapfile -t CATEGORIES < <(yq e '. | group_by(.category) | .[].0.category' "$TMP_FILTERED")

  for CATEGORY in "${CATEGORIES[@]}"; do
    if [ -n "$CATEGORY_FILTER" ] && [ "$CATEGORY" != "$CATEGORY_FILTER" ]; then
      continue
    fi

    echo "[$CATEGORY]"
    MATCHING_INDEXES=$(yq e "to_entries | map(select(.value.category == "$CATEGORY")) | .[].key" "$TMP_FILTERED")
    while read -r idx; do
      NAME=$(yq e ".[$idx].name" "$TMP_FILTERED")
      TOOL=$(yq e ".[$idx].tool" "$TMP_FILTERED")
      DESC=$(echo "$NAME" | sed 's/-/ /g' | sed 's/\<./\U&/g')
      echo "  $i) [$TOOL] $DESC"
      INDEX_MAP[$i]=$idx
      ((i++))
    done <<< "$MATCHING_INDEXES"
    echo
  done

  echo "Other:"
  echo "  $i) Exit"
  EXIT_OPTION=$i

  echo
  read -p "Enter your choice [1-$EXIT_OPTION]: " choice
  echo

  if [[ "$choice" == "$EXIT_OPTION" ]]; then
    echo "👋 Exiting."
    break
  fi

  IDX="${INDEX_MAP[$choice]}"

  if [[ -z "$IDX" ]]; then
    echo "❌ Invalid choice."
    read -p "Press Enter to continue..." _
    continue
  fi

  TOOL=$(yq e ".[$IDX].tool" "$TMP_FILTERED")
  SIM_SCRIPT=$(yq e ".[$IDX].sim" "$TMP_FILTERED")
  VALIDATE=$(yq e ".[$IDX].validate" "$TMP_FILTERED")
  LOG_MATCH=$(yq e ".[$IDX].log_match // """ "$TMP_FILTERED")

  if [[ ! -x "$SIM_SCRIPT" ]]; then
    echo "❌ Simulation script not found or not executable: $SIM_SCRIPT"
    read -p "Press Enter to continue..." _
    continue
  fi

  [[ "$TOOL" == "falco" ]] && wait_for_falco
  echo "▶️  Running simulation: $SIM_SCRIPT"
  bash "$SIM_SCRIPT"

  if [[ "$TOOL" == "falco" && "$VALIDATE" == "true" ]]; then
    validate_logs "$LOG_MATCH"
  fi

  echo
  read -p "Press Enter to return to main menu..." _
done

rm -f "$TMP_FILTERED"
