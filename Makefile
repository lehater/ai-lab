.DEFAULT_GOAL := help
.PHONY: help host-setup host-verify host-test github-setup github-verify docker-setup docker-verify docker-pull-test docker-test docker-compose-test s2-config-test s2-smoke

HOST_DIR := bootstrap/host
DOCKER_DIR := bootstrap/docker
S2_DIR := experiments/s2-compose-pilot

help:
	@printf '%s\n' \
	  'AI Lab — infrastructure commands' \
	  '  make host-setup     Install/configure S1 SSH transport after S0' \
	  '  make github-setup   Guide SSH key preparation and open GitHub keys page' \
	  '  make github-verify  Check GitHub SSH access (with interactive host-key review)' \
	  '  make host-verify    Check local S1 config and proxied HTTPS' \
	  '  make host-test      Run offline S1 regression tests' \
	  '  make docker-setup    Install Docker Engine/Compose after S1 (sudo)' \
	  '  make docker-verify   Check Docker/Compose and daemon proxy' \
	  '  make docker-pull-test  Pull/run hello-world through daemon proxy' \
	  '  make docker-test     Run offline Docker render/syntax checks' \
	  '  make docker-compose-test  Run disposable standard Compose bridge smoke' \
	  '  make s2-config-test  Validate S2.1 stateful Compose fixture' \
	  '  make s2-smoke        Test disposable stateful lifecycle and restore' \
	  '' \
	  'S0 remains independent: run bootstrap/stage0/bootstrap.sh from USB.' \
	  'If make is missing after S0, run: bash bootstrap/host/bootstrap.sh'

host-setup:
	@bash $(HOST_DIR)/bootstrap.sh

github-setup: host-setup
	@bash $(HOST_DIR)/github-setup.sh

github-verify:
	@bash $(HOST_DIR)/github-verify.sh

host-verify:
	@bash $(HOST_DIR)/verify.sh --local

host-test:
	@bash $(HOST_DIR)/tests/test-configure.sh
	@bash $(HOST_DIR)/tests/test-github-setup.sh

# S1-D accepted first module: separate from S1, requires sudo.
docker-setup:
	@bash $(DOCKER_DIR)/setup.sh

docker-verify:
	@bash $(DOCKER_DIR)/verify.sh --local

docker-pull-test:
	@bash $(DOCKER_DIR)/verify.sh --pull

docker-test:
	@bash $(DOCKER_DIR)/tests/test-render.sh

# Standard Compose bridge smoke; one disposable service, no published ports.
docker-compose-test:
	@bash $(DOCKER_DIR)/compose-smoke.sh

# S2.1 proposal: temporary acceptance workload, never a permanent service.
s2-config-test:
	@bash $(S2_DIR)/test-config.sh

s2-smoke:
	@bash $(S2_DIR)/smoke.sh
