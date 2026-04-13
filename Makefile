SHELL := /bin/bash
VERSION_FILE := VERSION
BRANCH := $(shell grep BRANCH $(VERSION_FILE) | cut -d'=' -f2)
VERSION := $(shell grep VERSION $(VERSION_FILE) | cut -d'=' -f2)
export DOCKER_LABEL := $(shell grep DOCKER_LABEL $(VERSION_FILE) | cut -d'=' -f2)
export DOCKER_REGISTRY := $(shell grep DOCKER_REGISTRY $(VERSION_FILE) | cut -d'=' -f2)

export REPOS_DIR := repos
export DEPLOY_DIR := $(REPOS_DIR)/taksa-deployments/platform/docker-compose
export BUILD_DIR := $(CURDIR)/_build
export GO_VERSION := 1.26.1
export GOOS := linux
export GOARCH := amd64
GO_TARBALL := go$(GO_VERSION).$(GOOS)-$(GOARCH).tar.gz
GO_URL := https://go.dev/dl/$(GO_TARBALL)

# Build environment variables
export GOROOT := $(BUILD_DIR)/go
export GOPATH := $(BUILD_DIR)/gopath
# Prepend local Go paths to PATH for all child processes
export PATH := $(GOROOT)/bin:$(GOPATH)/bin:$(PATH)

.DEFAULT_GOAL := help

.PHONY: all help repo-sync init clean \
	build-all build-traceability build-platform build-edge build-benthos \
	platform-init platform-up platform-down platform-logs

all: build-all

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

repo-sync: ## Initialize and update all submodules
	@echo "Initializing and updating submodules for branch $(BRANCH)..."
	git submodule update --init --recursive

	git submodule foreach '\
               if git ls-remote --exit-code --heads origin $(BRANCH) > /dev/null 2>&1; then \
                       echo "Checking out $(BRANCH) in $$name"; \
                       git checkout $(BRANCH) || git checkout -b $(BRANCH) origin/$(BRANCH); \
                       git pull origin $(BRANCH); \
               else \
                       DEFAULT_BRANCH=$$(git remote show origin | grep "HEAD branch" | sed "s/.*: //" | xargs); \
                       if [ -z "$$DEFAULT_BRANCH" ]; then \
                               echo "Error: Could not determine default branch for $$name. Please ensure origin remote is correctly configured."; \
                               exit 1; \
                       fi; \
                       echo "Branch $(BRANCH) not found in $$name, falling back to $$DEFAULT_BRANCH"; \
                       git checkout $$DEFAULT_BRANCH; \
                       git pull origin $$DEFAULT_BRANCH; \
               fi'

init: ## Setup Go toolchain, system tools (protoc, docker), and run make init in all submodules
	@echo "Setting up dev environment in $(BUILD_DIR)..."
	@mkdir -p $(BUILD_DIR)/gopath/bin
	@INSTALLED_VER=$$($(BUILD_DIR)/go/bin/go env GOVERSION 2>/dev/null | sed 's/^go//'); \
	if [ "$$INSTALLED_VER" != "$(GO_VERSION)" ]; then \
		echo "Downloading Go $(GO_VERSION) (found: $${INSTALLED_VER:-none})..."; \
		rm -rf $(BUILD_DIR)/go; \
		curl -L $(GO_URL) -o $(BUILD_DIR)/$(GO_TARBALL); \
		tar -C $(BUILD_DIR) -xzf $(BUILD_DIR)/$(GO_TARBALL); \
		rm $(BUILD_DIR)/$(GO_TARBALL); \
	fi
	@echo "Go toolchain ready ($(GO_VERSION))."
	@HOSTOS=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
	MISSING=""; \
	command -v protoc      >/dev/null 2>&1 || MISSING="$$MISSING protoc"; \
	command -v docker      >/dev/null 2>&1 || MISSING="$$MISSING docker"; \
	docker compose version >/dev/null 2>&1 || MISSING="$$MISSING docker-compose-plugin"; \
	if [ -n "$$MISSING" ]; then \
		echo ""; \
		echo "The following required tools are not installed:"; \
		for tool in $$MISSING; do echo "  • $$tool"; done; \
		echo ""; \
		printf "Install missing tools now? [y/N] "; \
		read REPLY; \
		if [ "$$REPLY" != "y" ] && [ "$$REPLY" != "Y" ]; then \
			echo "Aborting. All tools are required to build the project."; \
			exit 1; \
		fi; \
		if [ "$$HOSTOS" = "linux" ]; then \
			echo $$MISSING | grep -q protoc && { sudo apt-get update -qq && sudo apt-get install -y protobuf-compiler; }; \
			echo $$MISSING | grep -q docker && { \
				curl -fsSL https://get.docker.com | sh; \
				sudo systemctl enable --now docker; \
				sudo usermod -aG docker $$USER; \
				echo "NOTE: log out and back in (or run 'newgrp docker') for group membership to take effect."; \
			}; \
			echo $$MISSING | grep -q docker-compose-plugin && { sudo apt-get update -qq && sudo apt-get install -y docker-compose-plugin; }; \
		elif [ "$$HOSTOS" = "darwin" ]; then \
			echo $$MISSING | grep -q protoc && brew install protobuf; \
			{ echo $$MISSING | grep -q docker || echo $$MISSING | grep -q docker-compose-plugin; } && { \
				brew install --cask docker; \
				echo "NOTE: open Docker Desktop from Applications to complete setup, then re-run 'make init'."; \
				exit 0; \
			}; \
		else \
			echo "Cannot auto-install on $$HOSTOS. Install manually:"; \
			echo "  protoc: https://grpc.io/docs/protoc-installation/"; \
			echo "  docker: https://docs.docker.com/get-docker/"; \
			exit 1; \
		fi; \
	else \
		echo "protoc: $$(protoc --version)"; \
		echo "docker: $$(docker --version)"; \
		echo "docker compose: $$(docker compose version)"; \
	fi
	@echo "Running init in submodules..."
	@for repo in $(REPOS_DIR)/*; do \
		if [ -f $$repo/Makefile ] && $(MAKE) -n -C $$repo init >/dev/null 2>&1; then \
			echo "Initializing $$repo..."; \
			$(MAKE) -C $$repo init || exit 1; \
		fi \
	done
	@echo "Init complete."

build-all: build-platform build-traceability build-alerts ## Build all Docker images
	@echo "All images built successfully."

build-platform: ## Build all taksa-platform services (dm, user, ui)
	@$(MAKE) -C $(REPOS_DIR)/taksa-platform build

build-traceability: ## Build taksa-app-traceability Docker image
	@echo "Building taksa-app-traceability..."
	@$(MAKE) -C $(REPOS_DIR)/taksa-app-traceability build
	docker build -t $(DOCKER_REGISTRY)/taksa-app-traceability:$(DOCKER_LABEL) $(REPOS_DIR)/taksa-app-traceability/

build-edge: ## Build taksa-edge-umh Docker image
	@$(MAKE) -C $(REPOS_DIR)/taksa-edge-umh build

build-benthos: ## Build taksa-benthos-umh Docker image
	@echo "Building taksa-benthos-umh..."
	docker build -t $(DOCKER_REGISTRY)/taksa-benthos-umh:$(DOCKER_LABEL) $(REPOS_DIR)/taksa-benthos-umh/

platform-init: ## Initialize platform (certs, env, etc.)
	@echo "Initializing platform..."
	@if [ -d "$(DEPLOY_DIR)" ]; then \
		$(MAKE) -C $(DEPLOY_DIR) init; \
	else \
		echo "Error: Platform deployment directory not found. Did you run 'make repo-sync'?"; \
		exit 1; \
	fi

platform-up: ## Bring up the platform
	@echo "Bringing up platform..."
	@if [ -d "$(DEPLOY_DIR)" ]; then \
		$(MAKE) -C $(DEPLOY_DIR) up; \
	else \
		echo "Error: Platform deployment directory not found."; \
		exit 1; \
	fi

platform-down: ## Bring down the platform
	@echo "Bringing down platform..."
	@if [ -d "$(DEPLOY_DIR)" ]; then \
		$(MAKE) -C $(DEPLOY_DIR) down; \
	else \
		echo "Error: Platform deployment directory not found."; \
		exit 1; \
	fi

platform-logs: ## Follow platform container logs
	@if [ -d "$(DEPLOY_DIR)" ]; then \
		$(MAKE) -C $(DEPLOY_DIR) logs; \
	else \
		echo "Error: Platform deployment directory not found."; \
		exit 1; \
	fi

shellcmd: ## Run a command in the build environment (e.g., make shellcmd go version)
	@$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))

%:
	@:

clean: ## Clean up build artifacts (prune dangling Docker images and volumes)
	@echo "This will prune unused (dangling) Docker images and volumes."
	@echo "Docker will ask for confirmation before proceeding."
	docker image prune
	docker volume prune
