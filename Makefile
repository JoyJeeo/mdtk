# MDTK Makefile
# Conveniences for contributors. Run inside `conda activate mdtk`.

.PHONY: help test install smoke

help: ## Show available targets
	@echo "mdtk - Mac Developer Toolkit"
	@echo ""
	@echo "Targets:"
	@echo "  make install  Run install.zsh (env check + shellspec + symlink)."
	@echo "  make test     Run the shellspec suite."
	@echo "  make smoke    Run a few mdtk commands to sanity-check the skeleton."
	@echo "  make help     Show this message."

install: ## Set up the environment (run inside conda activate mdtk)
	./install.zsh

test: ## Run the shellspec test suite
	shellspec

smoke: ## Smoke-test the skeleton commands
	@echo "--- mdtk version ---"; mdtk version
	@echo "--- mdtk help (head) ---"; mdtk help | head -5
	@echo "--- mdtk logger (stub) ---"; mdtk logger; true
	@echo "--- mdtk bogus (unknown) ---"; mdtk bogus; true
