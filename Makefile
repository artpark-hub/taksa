SHELL := /bin/bash
VERSION_FILE := VERSION
BRANCH := $(shell grep BRANCH $(VERSION_FILE) | cut -d'=' -f2)
VERSION := $(shell grep VERSION $(VERSION_FILE) | cut -d'=' -f2)
export DOCKER_LABEL := $(shell grep DOCKER_LABEL $(VERSION_FILE) | cut -d'=' -f2)
export DOCKER_REGISTRY := $(shell grep DOCKER_REGISTRY $(VERSION_FILE) | cut -d'=' -f2)

REPOS_DIR := repos
BUILD_DIR := $(CURDIR)/build
GO_VERSION := 1.24.0
GO_TARBALL := go$(GO_VERSION).linux-amd64.tar.gz
GO_URL := https://go.dev/dl/$(GO_TARBALL)

# Build environment variables
export GOROOT := $(BUILD_DIR)/go
export GOPATH := $(BUILD_DIR)/gopath
# Prepend local Go paths to PATH for all child processes
export PATH := $(GOROOT)/bin:$(GOPATH)/bin:$(PATH)

.DEFAULT_GOAL := help

.PHONY: all help init-repo setup build clean \
	build-ui build-traceability build-services build-edge build-dm build-benthos \
	platform-init platform-up platform-down

all: build

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init-repo: ## Initialize and update all submodules
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

setup: ## Create dev setup with GOPATH/GOROOT in $(BUILD_DIR)
	@echo "Setting up dev environment in $(BUILD_DIR)..."
	@mkdir -p $(BUILD_DIR)/gopath/bin
	@if [ ! -d "$(BUILD_DIR)/go/bin" ]; then \
		echo "Downloading Go $(GO_VERSION)..."; \
		curl -L $(GO_URL) -o $(BUILD_DIR)/$(GO_TARBALL); \
		tar -C $(BUILD_DIR) -xzf $(BUILD_DIR)/$(GO_TARBALL); \
		rm $(BUILD_DIR)/$(GO_TARBALL); \
	fi
	@echo "Dev setup complete."

build-all: ## Build all repositories to create docker images
	@echo "Building all repositories..."
	@for repo in $(REPOS_DIR)/*; do \
		if [ -f $$repo/Makefile ]; then \
			echo "Building $$repo..."; \
			$(MAKE) -C $$repo build || exit 1; \
		fi \
	done

build-ui: ## Build taksa-ui
	@$(MAKE) -C $(REPOS_DIR)/taksa-ui build

build-traceability: ## Build taksa-app-traceability
	@$(MAKE) -C $(REPOS_DIR)/taksa-app-traceability build

build-platform: ## Build taksa-platform
	@$(MAKE) -C $(REPOS_DIR)/taksa-platform build

build-edge: ## Build taksa-edge-umh
	@$(MAKE) -C $(REPOS_DIR)/taksa-edge-umh build

build-dm: ## Build taksa-platform-dm
	@$(MAKE) -C $(REPOS_DIR)/taksa-platform-dm build

build-benthos: ## Build taksa-benthos-umh
	@$(MAKE) -C $(REPOS_DIR)/taksa-benthos-umh build

platform-init: ## Initialize platform (certs, env, etc.)
	@echo "Initializing platform..."
	@if [ -d "$(REPOS_DIR)/taksa-deployments/platform/docker-compose" ]; then \
		$(MAKE) -C $(REPOS_DIR)/taksa-deployments/platform/docker-compose init; \
	else \
		echo "Error: Platform deployment directory not found. Did you run 'make init-repo'?"; \
		exit 1; \
	fi

platform-up: ## Bring up the platform
	@echo "Bringing up platform..."
	@if [ -d "$(REPOS_DIR)/taksa-deployments/platform/docker-compose" ]; then \
		$(MAKE) -C $(REPOS_DIR)/taksa-deployments/platform/docker-compose up; \
	else \
		echo "Error: Platform deployment directory not found."; \
		exit 1; \
	fi

platform-down: ## Bring down the platform
	@echo "Bringing down platform..."
	@if [ -d "$(REPOS_DIR)/taksa-deployments/platform/docker-compose" ]; then \
		$(MAKE) -C $(REPOS_DIR)/taksa-deployments/platform/docker-compose down; \
	else \
		echo "Error: Platform deployment directory not found."; \
		exit 1; \
	fi

clean: ## Clean up build artifacts (prune dangling Docker images and volumes)
	@echo "This will prune unused (dangling) Docker images and volumes."
	@echo "Docker will ask for confirmation before proceeding."
	docker image prune
	docker volume prune
