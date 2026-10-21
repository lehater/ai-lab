.DEFAULT_GOAL := help
.PHONY: help host-setup host-verify host-test github-setup github-verify

HOST_DIR := bootstrap/host

help:
	@printf '%s\n' \
	  'AI Lab — infrastructure commands' \
	  '  make host-setup     Install/configure S1 SSH transport after S0' \
	  '  make github-setup   Guide SSH key preparation and open GitHub keys page' \
	  '  make github-verify  Check GitHub SSH access (with interactive host-key review)' \
	  '  make host-verify    Check local S1 config and proxied HTTPS' \
	  '  make host-test      Run offline S1 regression tests' \
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
