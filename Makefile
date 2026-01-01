# Veil DSL Workshop Makefile
# Veil: A DSL for Verified Information-Flow Security in Dafny

SHELL := /bin/sh
.DEFAULT_GOAL := help

# Directories
DOCS_DIR := docs
PAPERS_DIR := $(DOCS_DIR)/papers
TUTORIALS_DIR := tutorials
SRC_DIR := src

# URLs
VEIL_PAPER_URL := https://verse-lab.org/papers/veil-dafny26.pdf
VEIL_PAPER := $(PAPERS_DIR)/veil-dafny26.pdf

# Tools
CURL := curl
LEAN := lean
LAKE := lake

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

# =============================================================================
# Setup Targets
# =============================================================================

.PHONY: setup
setup: dirs paper submodules check-lean ## Complete setup: dirs, paper, submodules, lean check
	@echo "✓ Setup complete"

.PHONY: dirs
dirs: ## Create project directories
	@mkdir -p $(DOCS_DIR) $(PAPERS_DIR) $(TUTORIALS_DIR) $(SRC_DIR)
	@echo "✓ Created directories"

# =============================================================================
# Paper Download
# =============================================================================

.PHONY: paper
paper: $(VEIL_PAPER) ## Download the Veil paper

$(VEIL_PAPER): | $(PAPERS_DIR)
	@echo "Downloading Veil paper..."
	@$(CURL) -sSL -o $@ $(VEIL_PAPER_URL)
	@echo "✓ Downloaded: $@"

$(PAPERS_DIR):
	@mkdir -p $@

.PHONY: paper-clean
paper-clean: ## Remove downloaded paper
	@rm -f $(VEIL_PAPER)
	@echo "✓ Removed paper"

# =============================================================================
# Submodule Management
# =============================================================================

.PHONY: submodules
submodules: ## Initialize and update git submodules
	@echo "Checking git submodules..."
	@if [ -f .gitmodules ]; then \
		git submodule update --init --recursive; \
		echo "✓ Submodules updated"; \
	else \
		echo "✓ No submodules configured"; \
	fi

.PHONY: submodules-status
submodules-status: ## Show status of git submodules
	@echo "Git submodule status:"
	@if [ -f .gitmodules ]; then \
		git submodule status --recursive; \
	else \
		echo "  No submodules configured"; \
	fi

.PHONY: submodules-check
submodules-check: ## Verify submodules are properly initialized
	@echo "Checking submodule integrity..."
	@if [ -f .gitmodules ]; then \
		git submodule foreach 'git status --porcelain' | \
			( grep -v "^Entering" || true ); \
		echo "✓ Submodule check complete"; \
	else \
		echo "✓ No submodules to check"; \
	fi

# =============================================================================
# Lean 4 Verification
# =============================================================================

# Toolchain from lean-toolchain file
LEAN_TOOLCHAIN := $(shell cat lean-toolchain 2>/dev/null || echo "leanprover/lean4:v4.23.0")

# FreeBSD pkg lean4 requires these environment variables
# Note: FreeBSD lean4 pkg (as of 4.23.0) has a known issue where the lean
# binary fails with "failed to locate application". Lake works with LAKE_HOME.
FREEBSD_LEAN_ENV := LAKE_HOME=/usr/local LEAN_SYSROOT=/usr/local

.PHONY: elan-install
elan-install: ## Install elan and download Lean toolchain (Linux/macOS)
	@echo "Installing elan (Lean version manager)..."
	@case "$$(uname)" in \
		FreeBSD) \
			echo "On FreeBSD, use: pkg install lean4"; \
			echo "Note: FreeBSD lean4 pkg has known issues."; \
			;; \
		*) \
			if [ ! -d "$$HOME/.elan" ]; then \
				curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y; \
				echo "✓ Elan installed"; \
			else \
				echo "✓ Elan already installed"; \
			fi; \
			echo "Installing toolchain: $(LEAN_TOOLCHAIN)..."; \
			$$HOME/.elan/bin/elan toolchain install $(LEAN_TOOLCHAIN); \
			$$HOME/.elan/bin/elan default $(LEAN_TOOLCHAIN); \
			echo "✓ Toolchain installed"; \
			;; \
	esac

.PHONY: check-lean
check-lean: ## Check if Lean 4 is installed and show version
	@echo "Checking Lean 4 installation..."
	@if [ -x "$$HOME/.elan/bin/lean" ] && $$HOME/.elan/bin/lean --version 2>/dev/null; then \
		echo "✓ Lean found (elan): $$HOME/.elan/bin/lean"; \
	elif pkg info lean4 >/dev/null 2>&1; then \
		echo "✓ Lean 4 installed via FreeBSD pkg"; \
		pkg info lean4 | grep Version; \
		echo "  Note: FreeBSD lean4 pkg has known runtime issues"; \
	elif command -v $(LEAN) >/dev/null 2>&1 && $(LEAN) --version 2>/dev/null; then \
		echo "✓ Lean found: $$(which $(LEAN))"; \
	else \
		echo "✗ Lean 4 not found"; \
		echo "  Linux/macOS: gmake elan-install"; \
		echo "  FreeBSD: pkg install lean4"; \
		exit 1; \
	fi

.PHONY: check-lake
check-lake: ## Check if Lake (Lean build tool) is installed
	@echo "Checking Lake installation..."
	@if [ -x "$$HOME/.elan/bin/lake" ] && $$HOME/.elan/bin/lake --version 2>/dev/null; then \
		echo "✓ Lake found (elan): $$HOME/.elan/bin/lake"; \
	elif $(FREEBSD_LEAN_ENV) $(LAKE) --version 2>/dev/null; then \
		echo "✓ Lake found (FreeBSD pkg)"; \
	elif command -v $(LAKE) >/dev/null 2>&1 && $(LAKE) --version 2>/dev/null; then \
		echo "✓ Lake found: $$(which $(LAKE))"; \
	else \
		echo "✗ Lake not found"; \
		exit 1; \
	fi

.PHONY: check-tools
check-tools: check-lean check-lake check-racket ## Check all required tools
	@echo "✓ All tools verified"

.PHONY: lean-build
lean-build: ## Build Lean proofs
	@echo "Building Lean proofs..."
	@if [ -x "$$HOME/.elan/bin/lake" ]; then \
		$$HOME/.elan/bin/lake build; \
	elif pkg info lean4 >/dev/null 2>&1; then \
		echo "FreeBSD lean4 pkg has known build issues."; \
		echo "The lean binary fails with 'failed to locate application'."; \
		echo "This appears to be a packaging bug. Lake partially works:"; \
		$(FREEBSD_LEAN_ENV) $(LAKE) --version; \
		echo "Attempting build (may fail)..."; \
		$(FREEBSD_LEAN_ENV) $(LAKE) build || echo "Build failed - see above"; \
	else \
		$(LAKE) build; \
	fi

.PHONY: lean-status
lean-status: ## Show Lean installation status and known issues
	@echo "Lean 4 Status"
	@echo "============="
	@echo ""
	@echo "Platform: $$(uname -s) $$(uname -r)"
	@echo ""
	@if pkg info lean4 >/dev/null 2>&1; then \
		echo "FreeBSD pkg lean4 installed:"; \
		pkg info lean4 | grep -E 'Version|Installed'; \
		echo ""; \
		echo "Known Issues:"; \
		echo "  - lean binary: 'failed to locate application' error"; \
		echo "  - lake binary: works with LAKE_HOME=/usr/local"; \
		echo "  - lean-build: fails due to lean binary issue"; \
		echo ""; \
		echo "Workaround: Use Linux VM or container for Lean proofs"; \
	elif [ -x "$$HOME/.elan/bin/lean" ]; then \
		echo "Elan installation found"; \
		$$HOME/.elan/bin/lean --version; \
	else \
		echo "No Lean installation found"; \
	fi

# =============================================================================
# Racket Contract Examples
# =============================================================================

RACKET := racket

.PHONY: check-racket
check-racket: ## Check if Racket is installed
	@echo "Checking Racket installation..."
	@if command -v $(RACKET) >/dev/null 2>&1; then \
		echo "✓ Racket found: $$(which $(RACKET))"; \
		$(RACKET) --version; \
	else \
		echo "✗ Racket not found"; \
		echo "  Install via: pkg install racket"; \
		exit 1; \
	fi

.PHONY: racket-chaos
racket-chaos: ## Run the chaos comparator contract demo
	@echo "Running chaos comparator demo..."
	@$(RACKET) $(SRC_DIR)/chaos-comparator.rkt

# =============================================================================
# Tutorial Targets
# =============================================================================

.PHONY: tutorial-init
tutorial-init: dirs ## Initialize tutorial structure
	@echo "Creating tutorial structure..."
	@mkdir -p $(TUTORIALS_DIR)/01-intro
	@mkdir -p $(TUTORIALS_DIR)/02-basic-veil
	@mkdir -p $(TUTORIALS_DIR)/03-information-flow
	@mkdir -p $(TUTORIALS_DIR)/04-verification
	@echo "✓ Tutorial directories created"

# =============================================================================
# Cleanup
# =============================================================================

.PHONY: clean
clean: ## Clean generated files
	@rm -rf $(DOCS_DIR)/papers/*.pdf
	@echo "✓ Cleaned"

.PHONY: distclean
distclean: clean ## Deep clean including all generated content
	@rm -rf build/ .lake/
	@echo "✓ Distclean complete"

# =============================================================================
# Info Targets
# =============================================================================

.PHONY: info
info: ## Show project information
	@echo "Veil DSL Workshop"
	@echo "================"
	@echo "Paper: $(VEIL_PAPER_URL)"
	@echo ""
	@echo "Veil is a DSL for verified information-flow security in Dafny."
	@echo "It enables developers to write security policies and verify"
	@echo "that their code adheres to these policies."

.PHONY: status
status: ## Show status of setup
	@echo "Setup Status:"
	@echo "-------------"
	@[ -f $(VEIL_PAPER) ] && echo "✓ Paper downloaded" || echo "✗ Paper not downloaded"
	@command -v $(LEAN) >/dev/null 2>&1 && echo "✓ Lean 4 installed" || echo "✗ Lean 4 not installed"
	@command -v $(LAKE) >/dev/null 2>&1 && echo "✓ Lake installed" || echo "✗ Lake not installed"
	@[ -f .gitmodules ] && echo "✓ Submodules configured" || echo "○ No submodules"
