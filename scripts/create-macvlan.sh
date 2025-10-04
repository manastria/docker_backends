#!/usr/bin/env bash
set -euo pipefail

# Charger .env si présent pour NET_NAME/SUBNET/GATEWAY
if [ -f ".env" ]; then
  set -a
  . ./.env
  set +a
fi

NET_NAME="${NET_NAME:-macvlan_lan}"
SUBNET="${SUBNET:-10.10.0.0/24}"
GATEWAY="${GATEWAY:-10.10.0.1}"

# Détection de l'interface par défaut (parent du macvlan)
PARENT_IF="$(ip route show default | awk '{print $5}' | head -n1)"
if [[ -z "${PARENT_IF}" ]]; then
  echo "Impossible de détecter l'interface par défaut." >&2
  exit 1
fi

# Idempotence : ne rien faire si le réseau existe déjà
if docker network inspect "${NET_NAME}" >/dev/null 2>&1; then
  echo "Réseau ${NET_NAME} déjà présent."
  exit 0
fi

echo "Création du réseau macvlan '${NET_NAME}' (subnet=${SUBNET}, gw=${GATEWAY}, parent=${PARENT_IF})…"
docker network create -d macvlan "${NET_NAME}"   --subnet="${SUBNET}" --gateway="${GATEWAY}"   -o parent="${PARENT_IF}"
echo "OK."
