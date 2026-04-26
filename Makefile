# =============================================================================
# NetworkMemories — Metal Gear Online 1 — Makefile
# =============================================================================

DC = docker compose -f docker-compose.yml

.PHONY: help init build run run-daemon stop down logs shell-db backup restore \
        disable-systemd-resolved enable-systemd-resolved renew-certs

help: ## Show all available commands
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS=":.*##"}; {printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2}'

init: ## First-time setup: create .env and required directories
	@if [ ! -f .env ]; then \
	  cp .env.example .env; \
	  echo "✅ .env created — edit it before continuing!"; \
	else \
	  echo "⚠️  .env already exists, skipping."; \
	fi
	@mkdir -p dbdata backups
	@echo "✅ Init done. Edit .env then run: make build"

build: ## Build all containers
	$(DC) build

run: ## Start all services (foreground)
	$(DC) up

run-daemon: ## Start all services (background)
	$(DC) up -d

stop: ## Stop services (keep data)
	$(DC) stop

down: ## Remove containers (keep volumes)
	$(DC) down

down-volumes: ## ⚠️  Remove containers AND volumes (data loss!)
	$(DC) down -v

logs: ## Follow all logs
	$(DC) logs -f

logs-server: ## Follow MGO1 server logs only
	$(DC) logs -f mgops-server

logs-gateway: ## Follow gateway logs only
	$(DC) logs -f mgops-gateway

logs-dns: ## Follow DNS logs only
	$(DC) logs -f mgops-dns

shell-db: ## Open MySQL shell
	$(DC) exec biomysql mysql \
	  -u$$(grep ^MYSQL_USER .env | cut -d= -f2) \
	  -p$$(grep ^MYSQL_PASSWORD .env | cut -d= -f2) \
	  $$(grep ^MYSQL_DATABASE .env | cut -d= -f2)

backup: ## Backup database and data
	@bash scripts/backup.sh

restore: ## Restore from latest backup
	@bash scripts/restore.sh

renew-certs: ## Renew TLS certificates
	$(DC) exec mgops-gateway /var/www/reissue-certs.sh
	$(DC) restart mgops-gateway

disable-systemd-resolved: ## Disable systemd-resolved (Linux — free port 53)
	sudo systemctl stop systemd-resolved && sudo systemctl disable systemd-resolved
	@echo "✅ systemd-resolved disabled"

enable-systemd-resolved: ## Re-enable systemd-resolved after stopping server
	sudo systemctl enable systemd-resolved && sudo systemctl start systemd-resolved
	@echo "✅ systemd-resolved re-enabled"
