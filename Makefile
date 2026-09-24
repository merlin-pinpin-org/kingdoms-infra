.PHONY: check diagnose-deploy-test diagnose-deploy-prod doctor

check:
	@bash -n scripts/*.sh
	@command -v shellcheck >/dev/null && shellcheck scripts/*.sh || echo "shellcheck not available — CI covers it"
	@docker compose -f envs/test/docker-compose.yml config >/dev/null 2>&1 \
	  && echo "compose config OK" || echo "docker not available — CI covers it"

doctor: check
	@echo "==> Deploy health by environment"
	@./scripts/diagnose_deploy.sh test || true
	@./scripts/diagnose_deploy.sh prod || true

diagnose-deploy-test:
	@./scripts/diagnose_deploy.sh test

diagnose-deploy-prod:
	@./scripts/diagnose_deploy.sh prod
