# MDTK Makefile
# Conveniences for contributors. Run inside `conda activate mdtk`.

.PHONY: help test testone install smoke

help: ## Show available targets
	@echo "mdtk - Mac Developer Toolkit"
	@echo ""
	@echo "Targets:"
	@echo "  make install  Run install.zsh (env check + shellspec + symlink)."
	@echo "  make test     Run the shellspec suite (under tests/)."
	@echo "  make testone FILE=tests/bin/mdtk_spec.sh  Run one spec file."
	@echo "  make smoke    Run a few mdtk commands to sanity-check the skeleton."
	@echo "  make help     Show this message."

install: ## Set up the environment (run inside conda activate mdtk)
	./install.zsh

test: ## Run the shellspec suite (under tests/)
	shellspec

# Run one spec file:  make testone tests/bin/mdtk_spec.sh
testone: ## Run a single spec file (usage: make testone tests/path_spec.sh)
	shellspec $(FILE)

smoke: ## Smoke-test the skeleton commands
	@echo "--- mdtk version ---"; mdtk version
	@echo "--- mdtk help (head) ---"; mdtk help | head -5
	@echo "--- mdtk logger (stub) ---"; mdtk logger; true
	@echo "--- mdtk bogus (unknown) ---"; mdtk bogus; true
