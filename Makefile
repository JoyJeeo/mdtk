# MDTK Makefile
# Conveniences for contributors. Run inside `conda activate mdtk`.

.PHONY: help lint syntax test testone install smoke

help: ## Show available targets
	@echo "mdtk - Mac Developer Toolkit"
	@echo ""
	@echo "Targets:"
	@echo "  make install  Run scripts/dev-install.zsh (env check + shellspec + shellcheck + symlink)."
	@echo "  make lint    Parse-check (zsh -n) + shellcheck advisory (DoD gate, .ai/DOD.md)."
	@echo "  make syntax   Parse-check source files with zsh -n."
	@echo "  make test     Run the shellspec suite (under tests/)."
	@echo "  make testone FILE=tests/bin/mdtk_spec.sh  Run one spec file."
	@echo "  make smoke    Run a few MDTK commands as a CLI sanity check."
	@echo "  make help     Show this message."

install: ## Set up the dev environment (run inside conda activate mdtk)
	./scripts/dev-install.zsh

# Parse check: the real "compiles" gate for a zsh project.
syntax: ## Parse-check all zsh source with zsh -n
	@echo "--- zsh -n (parse) ---"
	@files=$$(git ls-files 'src/**/*.zsh' 'bin/*' install.sh scripts/dev-install.zsh scripts/install.sh 2>/dev/null); \
	if [ -z "$$files" ]; then echo "(no files)"; else \
		rc=0; for f in $$files; do zsh -n "$$f" || rc=1; done; \
		exit $$rc; \
	fi

# Advisory lint. ShellCheck does not support zsh natively; we run it in sh
# mode to catch bash/sh-compatible issues. zsh-only constructs will flag and
# are expected — treat as advisory, not a hard gate. The hard gate is `syntax`.
shellcheck-advisory:
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo "(shellcheck not installed; advisory skipped)" >&2; \
		exit 0; \
	fi
	@echo "--- shellcheck (advisory, sh mode; zsh-isms expected) ---"
	@files=$$(git ls-files 'src/**/*.zsh' 'bin/*' install.sh scripts/dev-install.zsh scripts/install.sh 2>/dev/null); \
	if [ -z "$$files" ]; then echo "(no files)"; else \
		shellcheck -x -s sh $$files || \
			echo "(shellcheck flagged above; review real issues, ignore zsh-isms)"; \
	fi

lint: syntax shellcheck-advisory ## DoD gate: parse-check (hard) + shellcheck (advisory)

test: ## Run the shellspec suite (under tests/)
	shellspec

# Run one spec file:  make testone tests/bin/mdtk_spec.sh
testone: ## Run a single spec file (usage: make testone tests/path_spec.sh)
	shellspec $(FILE)

smoke: ## Smoke-test representative CLI commands
	@echo "--- mdtk version ---"; ./bin/mdtk version
	@echo "--- mdtk help (head) ---"; ./bin/mdtk help | head -5
	@echo "--- mdtk logger ---"; ./bin/mdtk logger --info "smoke"
	@echo "--- mdtk bogus (unknown) ---"; ./bin/mdtk bogus; true
