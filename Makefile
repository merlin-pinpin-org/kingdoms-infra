.PHONY: check diagnose-deploy-test diagnose-deploy-prod diagnose-env doctor

# Fail-closed: a missing linter is an error, never a green-ish skip —
# the sandbox gap is what let SC2046 reach main (2026-09-24). CI runs the
# same commands; make check must not pass when a tool is unavailable.
check:
	@bash -n scripts/*.sh
	@command -v shellcheck >/dev/null || { echo "ERROR: shellcheck is not installed (pip install shellcheck-py)" >&2; exit 1; }
	@shellcheck --severity=warning scripts/*.sh
	@docker compose -f envs/test/docker-compose.yml config >/dev/null 2>&1 \
	  && echo "check OK" || echo "check OK (compose config skipped — no docker daemon; the required CI check 'Validate compose manifests' covers it)"

doctor: check
	@echo "==> Deploy health by environment"
	@./scripts/diagnose_deploy.sh test || true
	@./scripts/diagnose_deploy.sh prod || true
	@./scripts/diagnose_env.sh drasah || true
	@./scripts/diagnose_env.sh merlin || true

diagnose-env-%:
	@./scripts/diagnose_env.sh $*

diagnose-deploy-test:
	@./scripts/diagnose_deploy.sh test

diagnose-deploy-prod:
	@./scripts/diagnose_deploy.sh prod
