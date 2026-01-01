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

.PHONY: check-lean
check-lean: ## Check if Lean 4 is installed and show version
	@echo "Checking Lean 4 installation..."
	@if command -v $(LEAN) >/dev/null 2>&1; then \
		echo "✓ Lean found: $$(which $(LEAN))"; \
		$(LEAN) --version; \
	else \
		echo "✗ Lean 4 not found in PATH"; \
		echo "  Install via: curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh"; \
		exit 1; \
	fi

.PHONY: check-lake
check-lake: ## Check if Lake (Lean build tool) is installed
	@echo "Checking Lake installation..."
	@if command -v $(LAKE) >/dev/null 2>&1; then \
		echo "✓ Lake found: $$(which $(LAKE))"; \
		$(LAKE) --version; \
	else \
		echo "✗ Lake not found (installed with Lean 4)"; \
		exit 1; \
	fi

.PHONY: check-tools
check-tools: check-lean check-lake ## Check all required tools
	@echo "✓ All tools verified"

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
