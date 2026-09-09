PROD = docker compose -f compose/docker-compose.prod.yml
DEV  = docker compose -f compose/docker-compose.dev.yml

.PHONY: prod-build prod-build-no-cache prod-up prod-down prod-logs prod-ps prod-restart prod-run
.PHONY: dev-build dev-build-no-cache dev-up dev-down dev-logs dev-ps dev-restart dev-run

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

# e.g. make dev-run JOB=spx_short_options
dev-run:
	$(DEV) up $(JOB)
