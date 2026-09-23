COMPOSE_BASE = -f services/postgres/compose.yml \
               -f services/tickrake/compose.yml \
               -f services/options-monitor/compose.yml \
               -f services/mlflow/compose.yml \
               -f services/monitoring/compose.yml \
               -f services/minio/compose.yml

PROD = ENV=prod COMPOSE_PROFILES=prod docker compose --project-directory . $(COMPOSE_BASE) -f deploy/prod.yml
PROD_DOWN = ENV=prod COMPOSE_PROFILES=prod,dev docker compose --project-directory . $(COMPOSE_BASE) -f deploy/prod.yml
DEV  = ENV=dev COMPOSE_PROFILES=dev docker compose --project-directory . $(COMPOSE_BASE) -f deploy/dev.yml
RESEARCH = ENV=prod COMPOSE_PROFILES=research docker compose --project-directory . $(COMPOSE_BASE) -f deploy/prod.yml
DATA_INGESTION = ENV=prod COMPOSE_PROFILES=data-ingestion docker compose --project-directory . $(COMPOSE_BASE) -f deploy/prod.yml

.PHONY: hooks-install secrets-check
.PHONY: prod-build prod-build-no-cache prod-up prod-down prod-logs prod-ps prod-restart prod-run
.PHONY: dev-build dev-build-no-cache dev-up dev-down dev-logs dev-ps dev-restart dev-run
.PHONY: research-up research-down research-logs research-ps research-restart
.PHONY: data-ingestion-up data-ingestion-down data-ingestion-logs data-ingestion-ps data-ingestion-restart

hooks-install:
	@command -v gitleaks >/dev/null || { echo "Install gitleaks first: brew install gitleaks"; exit 1; }
	git config core.hooksPath scripts/git-hooks

secrets-check:
	gitleaks git .

prod-build:
	$(PROD) build

prod-build-no-cache:
	$(PROD) build --no-cache

prod-up:
	$(PROD) up -d

prod-down:
	$(PROD_DOWN) down

prod-logs:
	$(PROD) logs -f

prod-ps:
	$(PROD) ps

prod-restart:
	$(PROD) restart

# e.g. make prod-run JOB=spx_0dte_options
prod-run:
	$(PROD) up $(JOB)

research-up:
	$(RESEARCH) up -d

research-down:
	$(RESEARCH) down

research-logs:
	$(RESEARCH) logs -f

research-ps:
	$(RESEARCH) ps

research-restart:
	$(RESEARCH) restart

data-ingestion-up:
	$(DATA_INGESTION) up -d

data-ingestion-down:
	$(DATA_INGESTION) down

data-ingestion-logs:
	$(DATA_INGESTION) logs -f

data-ingestion-ps:
	$(DATA_INGESTION) ps

data-ingestion-restart:
	$(DATA_INGESTION) restart

dev-build:
	$(DEV) build

dev-build-no-cache:
	$(DEV) build --no-cache

dev-up:
	$(DEV) up -d

dev-down:
	$(DEV) down

dev-logs:
	$(DEV) logs -f

dev-ps:
	$(DEV) ps

dev-restart:
	$(DEV) restart

# e.g. make dev-run JOB=futures_candles
dev-run:
	$(DEV) up $(JOB)
