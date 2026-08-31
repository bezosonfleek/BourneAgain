#!/usr/bin/env bash

set -euo pipefail

kctl="microk8s.kubectl"
command -v fzf >/dev/null || { echo "fzf is required" >&2; exit 1; }

read -rp "Choose action (get/logs): " action

read -rp "Namespace: " namespace
namespace="${namespace:-default}"

case "$action" in
  get)
    $kctl get pods -n "$namespace"
    ;;
  logs)
    pod=$($kctl get pods -n "$namespace" --field-selector=status.phase=Running \
          -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | fzf)
    [[ -n "$pod" ]] && $kctl logs -n "$namespace" -f "$pod"
    ;;
  *)
    echo "Unknown action: $action (expected 'get' or 'logs')" >&2
    exit 1
    ;;
esac
