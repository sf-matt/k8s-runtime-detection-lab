#!/bin/bash

REGISTRY_FILE="detections/_registry.yaml"

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
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ -n "$CATEGORY_FILTER" ]; then
  mapfile -t ENTRIES < <(yq e -o=json ".[] | select(.category == \"$CATEGORY_FILTER\")" "$REGISTRY_FILE")
else
  mapfile -t ENTRIES < <(yq e -o=json '.[]' "$REGISTRY_FILE")
fi

if [ ${#ENTRIES[@]} -eq 0 ]; then
  echo "❌ No tests found for the selected criteria."
  exit 1
fi

function validate_logs() {
  KEYWORD="$1"
  if [[ -n "$KEYWORD" ]]; then
    echo "[*] Checking logs for: $KEYWORD"
    ./lifecycle/check-falco-logs.sh "$KEYWORD"
  fi
}

if [ "$AUTO_MODE" = true ]; then
  echo "🔁 Running all detections in auto mode..."
  echo

  for entry in "${ENTRIES[@]}"; do
    NAME=$(echo "$entry" | yq e '.name' -)
    SIM_SCRIPT=$(echo "$entry" | yq e '.sim' -)
    VALIDATE=$(echo "$entry" | yq e '.validate' -)

    echo "▶️  [$NAME] Running: $SIM_SCRIPT"
    if [ -x "$SIM_SCRIPT" ]; then
      bash "$SIM_SCRIPT"
  TOOL=$(echo "$SELECTED" | yq e '.tool' -)
  if [[ "$TOOL" == "falco" && -n "$VALIDATE" ]]; then
    validate_logs "$VALIDATE"
  fi
    else
      echo "❌ Simulation script not found or not executable: $SIM_SCRIPT"
    fi
    echo
  done

  echo "✅ Auto run complete."
  exit 0
fi

while true; do
  clear
  echo "🧪 Runtime Detection Lab (Dynamic Menu)"
  echo "======================================="
  echo

  declare -A INDEX_MAP
  i=1

  for CATEGORY in $(yq e '.[].category' "$REGISTRY_FILE" | sort | uniq); do
    if [ -n "$CATEGORY_FILTER" ] && [ "$CATEGORY" != "$CATEGORY_FILTER" ]; then
      continue
    fi

    echo "[$CATEGORY]"
    mapfile -t GROUP < <(yq e ".[] | select(.category == \"$CATEGORY\") | @json" "$REGISTRY_FILE")
    for entry in "${GROUP[@]}"; do
      NAME=$(echo "$entry" | yq e '.name' -)
      TOOL=$(echo "$entry" | yq e '.tool' -)
      DESC=$(echo "$NAME" | sed 's/-/ /g' | sed 's/\<./\U&/g')
      echo "  $i) [$TOOL] $DESC"
      INDEX_MAP[$i]="$entry"
      ((i++))
    done
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

  SELECTED="${INDEX_MAP[$choice]}"

  if [[ -z "$SELECTED" ]]; then
    echo "❌ Invalid choice."
    read -p "Press Enter to continue..." _
    continue
  fi

  SIM_SCRIPT=$(echo "$SELECTED" | yq e '.sim' -)
  VALIDATE=$(echo "$SELECTED" | yq e '.validate' -)

  if [[ ! -x "$SIM_SCRIPT" ]]; then
    echo "❌ Simulation script not found or not executable: $SIM_SCRIPT"
    read -p "Press Enter to continue..." _
    continue
  fi

  echo "▶️  Running simulation: $SIM_SCRIPT"
  bash "$SIM_SCRIPT"
  TOOL=$(echo "$SELECTED" | yq e '.tool' -)
  if [[ "$TOOL" == "falco" && -n "$VALIDATE" ]]; then
    validate_logs "$VALIDATE"
  fi

  echo
  read -p "Press Enter to return to main menu..." _
done