COMPOSE_BASE = -f services/postgres/compose.yml \
               -f services/tickrake/compose.yml \
               -f services/mlflow/compose.yml \
               -f services/monitoring/compose.yml \
               -f services/minio/compose.yml

PROD = ENV=prod COMPOSE_PROFILES=prod docker compose --project-directory . $(COMPOSE_BASE) -f deploy/prod.yml
DEV  = ENV=dev COMPOSE_PROFILES=dev docker compose --project-directory . $(COMPOSE_BASE) -f deploy/dev.yml
RESEARCH = ENV=prod COMPOSE_PROFILES=research docker compose --project-directory . $(COMPOSE_BASE) -f deploy/prod.yml

.PHONY: prod-build prod-build-no-cache prod-up prod-down prod-logs prod-ps prod-restart prod-run
.PHONY: dev-build dev-build-no-cache dev-up dev-down dev-logs dev-ps dev-restart dev-run
.PHONY: research-up research-down research-logs research-ps research-restart

prod-build:
	$(PROD) build

prod-build-no-cache:
	$(PROD) build --no-cache

prod-up:
	$(PROD) up -d

prod-down:
	$(PROD) down

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
