#!/usr/bin/env bash
set -euo pipefail
ACTION="${1:-up}"
if [ -f ".env" ]; then set -a; . ./.env; set +a; fi
HOST_SHIM_NAME="${HOST_SHIM_NAME:-macvlan0}"
HOST_SHIM_IP="${HOST_SHIM_IP:-10.10.0.200}"
PARENT_IF="${PARENT_IF:-}"
if [[ -z "$PARENT_IF" ]]; then PARENT_IF="$(ip route show default | awk '{print $5}' | head -n1 || true)"; fi
if [[ -z "$PARENT_IF" ]]; then echo "Impossible de détecter PARENT_IF"; exit 1; fi
exists() { ip link show "$1" >/dev/null 2>&1; }
addrset() { ip -brief addr show "$1" | awk '{print $3}' | grep -qE '^[0-9]'; }
case "$ACTION" in
  up)
    if ! exists "$HOST_SHIM_NAME"; then
      echo "Création $HOST_SHIM_NAME (parent=$PARENT_IF)…"
      sudo ip link add "$HOST_SHIM_NAME" link "$PARENT_IF" type macvlan mode bridge
    else
      echo "$HOST_SHIM_NAME existe déjà."
    fi
    if ! addrset "$HOST_SHIM_NAME"; then
      echo "Adresse ${HOST_SHIM_IP}/24 sur $HOST_SHIM_NAME…"
      sudo ip addr add "${HOST_SHIM_IP}/24" dev "$HOST_SHIM_NAME" || true
    fi
    sudo ip link set "$HOST_SHIM_NAME" up
    echo "OK. Test: curl http://10.10.0.101/"
    ;;
  down)
    if exists "$HOST_SHIM_NAME"; then
      echo "Suppression $HOST_SHIM_NAME…"
      sudo ip link del "$HOST_SHIM_NAME"
      echo "OK."
    else
      echo "$HOST_SHIM_NAME absent."
    fi
    ;;
  status)
    ip -brief addr show "$HOST_SHIM_NAME" || echo "$HOST_SHIM_NAME absent."
    ;;
  *)
    echo "Usage: $0 {up|down|status}"; exit 2;;
esac
