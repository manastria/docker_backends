# Backends DMZ (macvlan)

Deux serveurs web en DMZ avec une IP par conteneur (macvlan), pour alimenter un TP reverse‑proxy HAProxy.

## Prérequis
- Debian/Ubuntu avec Docker & Docker Compose v2 (`docker compose`).
- Accès au sous-réseau DMZ (ex. `10.10.0.0/24`) routé depuis le proxy via pare-feu.
- Avoir copié `.env.example` vers `.env` et ajusté si besoin.

## Mise en route rapide
```bash
cp -n .env.example .env   # si .env n'existe pas
make network              # crée le réseau macvlan (une seule fois)
make up                   # démarre node1 et node2
make ps                   # affiche l'état
```

## Test (sans HAProxy)
Depuis une autre machine du réseau DMZ (ou depuis la VM HaProxy / le pare-feu) :
```bash
curl http://10.10.0.101/
curl http://10.10.0.102/
```

> Rappel macvlan : l'hôte Docker **ne peut pas** joindre ses conteneurs macvlan (c'est normal).

## Cibles Make utiles
- `make network` : crée le réseau macvlan externe.
- `make up` : démarre les services.
- `make down` : arrête les services.
- `make restart` : redémarre.
- `make logs` : suit les logs.
- `make ps` : liste l'état des services.
- `make validate` : vérifie la configuration Compose.
- `make clean` : supprime les conteneurs/volumes **du projet** (pas le réseau macvlan).

## Variante TLS (facultatif, pour plus tard)
- Ajouter un dossier `tls/` (cert + key) et une conf nginx `listen 443 ssl;` par nœud.
- Pointer ensuite HAProxy vers `:443` et activer SNI côté backend.

## Déploiement GitHub
```bash
git clone https://github.com/manastria/docker_backends.git
cd docker_backends
cp .env.example .env
make network
make up
curl http://10.10.0.101/
curl http://10.10.0.102/
```