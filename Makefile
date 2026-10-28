COMPOSE_BASE = --env-file envs/secrets.env \
               -f services/postgres/compose.yml \
               -f services/tickrake/compose.yml \
               -f services/monitoring/compose.yml \
               -f services/minio/compose.yml

PROD = ENV=prod COMPOSE_PROFILES=prod docker compose --project-directory . $(COMPOSE_BASE) -f deploy/prod.yml

.PHONY: hooks-install secrets-check
.PHONY: prod-build prod-build-no-cache prod-up prod-down prod-restart prod-start prod-stop
.PHONY: publish-script-image publish-options-day publish-level-one-day publish-order-book-day

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
	$(PROD) down

prod-restart:
	$(PROD) restart

prod-start:
	@test -n "$(SERVICE)" || { echo "Set SERVICE to a Compose service name"; exit 1; }
	$(PROD) start $(SERVICE)

prod-stop:
	@test -n "$(SERVICE)" || { echo "Set SERVICE to a Compose service name"; exit 1; }
	$(PROD) stop $(SERVICE)

# Build the one-off CLI image from the current remote main branches.
publish-script-image:
	docker buildx build --load --pull \
	  --build-context tickrake=https://github.com/jwplatta/tickrake.git\#main \
	  --build-context tractatus=https://github.com/jwplatta/tractatus.git\#main \
	  -f services/publish-lakehouse/Dockerfile -t quant-infra-publish-day:latest .

publish-options-day:
	bash services/publish-lakehouse/run-one-off.sh options $(DATE)

publish-level-one-day:
	bash services/publish-lakehouse/run-one-off.sh level_one $(DATE)

publish-order-book-day:
	bash services/publish-lakehouse/run-one-off.sh order_book $(DATE)
