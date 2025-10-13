#!/usr/bin/env bash

# Active des options pour un script plus sûr :
# -e : quitte immédiatement si une commande échoue
# -u : quitte si on utilise une variable non définie
# -o pipefail : fait échouer une série de commandes pipe si l'une d'elles échoue
set -euo pipefail

echo "--- Début du script d'activation permanente du mode promiscuité ---"

# --- Étape 1 : Détection de l'interface réseau principale ---
echo "[1/4] Recherche de l'interface réseau par défaut..."
# La commande 'ip route' peut retourner plusieurs lignes, on s'assure de ne prendre que la première.
PARENT_IF=$(ip route show default | awk '{print $5}' | head -n1)

if [[ -z "${PARENT_IF}" ]]; then
  echo "ERREUR : Impossible de détecter l'interface réseau par défaut." >&2
  echo "Vérifiez la sortie de la commande 'ip route show default'." >&2
  exit 1
fi
echo "      -> Interface trouvée : ${PARENT_IF}"


# --- Étape 2 : Recherche de la connexion NetworkManager associée ---
echo "[2/4] Recherche de la connexion NetworkManager active pour '${PARENT_IF}'..."
# On filtre les connexions actives pour trouver celle qui correspond à notre interface.
# L'option -t permet une sortie simple (:) pour 'cut'.
CON_NAME=$(nmcli -t -f NAME,DEVICE connection show --active | grep ":${PARENT_IF}$" | cut -d: -f1)

if [[ -z "${CON_NAME}" ]]; then
  echo "ERREUR : Aucune connexion NetworkManager active n'a été trouvée pour l'interface '${PARENT_IF}'." >&2
  echo "Vérifiez que l'interface est bien gérée par NetworkManager ('nmcli device status')." >&2
  exit 1
fi
echo "      -> Connexion trouvée : ${CON_NAME}"


# --- Étape 3 : Vérification de l'état actuel du mode promiscuité ---
echo "[3/4] Vérification de l'état actuel de la propriété 'accept-all-mac-addresses'..."
# On utilise la bonne propriété cette fois-ci.
CURRENT_STATE=$(nmcli -g 802-3-ethernet.accept-all-mac-addresses connection show "${CON_NAME}")

# La valeur '1' signifie que le mode est déjà activé.
if [[ "${CURRENT_STATE}" == "1" ]]; then
  echo "      -> Le mode promiscuité (valeur=1) est déjà activé en permanence pour '${CON_NAME}'."
  echo "--- Script terminé. Aucune action n'était nécessaire. ---"
  exit 0
fi
echo "      -> Le mode promiscuité n'est pas encore activé (valeur actuelle : ${CURRENT_STATE:-'par défaut'})."


# --- Étape 4 : Activation permanente et application ---
echo "[4/4] Activation du mode promiscuité pour la connexion '${CON_NAME}'..."
# La commande 'nmcli connection modify' peut échouer si les permissions sont insuffisantes.
if ! nmcli connection modify "${CON_NAME}" 802-3-ethernet.accept-all-mac-addresses 1; then
    echo "ERREUR : La modification de la connexion a échoué. Exécutez-vous bien le script avec 'sudo' ?" >&2
    exit 1
fi
echo "      -> Propriété modifiée avec succès."

echo "      -> Réactivation de la connexion pour une prise en compte immédiate..."
# La réactivation assure que le changement est appliqué sans redémarrage.
if ! nmcli connection up "${CON_NAME}"; then
    echo "AVERTISSEMENT : La réactivation de la connexion a échoué. Le changement sera appliqué au prochain redémarrage." >&2
fi

echo ""
echo "✅ SUCCÈS : Le mode promiscuité pour l'interface ${PARENT_IF} (via la connexion '${CON_NAME}') est maintenant permanent."
echo "--- Script terminé. ---"