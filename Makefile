
SHELL := /bin/bash

# Charge .env si présent pour NET_NAME, SUBNET, GATEWAY, NODE1_IP, NODE2_IP
ifneq ("$(wildcard .env)","")
include .env
export
endif

PROJECT := backends

.PHONY: help network up down restart logs ps validate clean pull

help:
	@echo "Cibles disponibles :"
	@echo "  make network   - Crée le réseau macvlan externe (une fois)"
	@echo "  make up        - Démarre les conteneurs"
	@echo "  make down      - Arrête les conteneurs"
	@echo "  make restart   - Redémarre"
	@echo "  make logs      - Affiche les logs"
	@echo "  make ps        - Liste l'état des services"
	@echo "  make validate  - Valide la configuration Compose"
	@echo "  make pull      - Récupère/Met à jour les images"
	@echo "  make clean     - Supprime conteneurs/volumes du projet"

network:
	@bash scripts/create-macvlan.sh

up:
	docker compose -p $(PROJECT) up -d

down:
	docker compose -p $(PROJECT) down

restart: down up

logs:
	docker compose -p $(PROJECT) logs -f --tail=200

ps:
	docker compose -p $(PROJECT) ps

validate:
	docker compose -p $(PROJECT) config -q

pull:
	docker compose -p $(PROJECT) pull

clean:
	docker compose -p $(PROJECT) down -v --remove-orphans || true
