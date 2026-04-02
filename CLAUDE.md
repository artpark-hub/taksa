# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Taksa Factory OS is an open-source manufacturing IoT platform. This is the **meta-repository** that orchestrates 5 Git submodules under `repos/`, each with its own build system and CLAUDE.md.

## Build Commands

```bash
make init-repo          # Initialize/update all submodules (checks out branch from VERSION file)
make setup              # Download isolated Go 1.24.0 toolchain to build/
make build-all          # Build all services (Docker images)
make build-<service>    # Build one: build-ui, build-traceability, build-platform, build-edge, build-dm, build-benthos
make shellcmd <cmd>     # Run a command using the local Go toolchain (e.g., make shellcmd go version)
make platform-init      # Generate SSL certs and data dirs for local deployment
make platform-up        # Start full Docker Compose stack
make platform-down      # Stop the stack
make clean              # Prune dangling Docker images/volumes
```

Individual submodules have their own Makefiles with targets like `build`, `api` (proto codegen), `config`, and `wire` (DI generation).

## Architecture

### Meta-repo Orchestration

- `VERSION` controls branch (`BRANCH`), version (`VERSION`), Docker registry (`DOCKER_REGISTRY`), and image tag (`DOCKER_LABEL`) for the entire project.
- `Makefile` exports `GOROOT`, `GOPATH`, `PATH`, `DOCKER_REGISTRY`, and `DOCKER_LABEL` to all child builds. The Go toolchain is fully isolated in `build/` — no system Go required.
- `init-repo` checks out `BRANCH` in each submodule that has it, falls back to the submodule's default branch otherwise.

### Submodules (`repos/`)

| Submodule | Purpose | Stack |
|---|---|---|
| **taksa-platform** | Core platform monorepo: user-management, device-management, ui-service | Go (Kratos v2), Next.js 16, PostgreSQL |
| **taksa-app-traceability** | MES traceability (64+ gRPC/REST endpoints) | Go (Kratos v2), PostgreSQL + TimescaleDB |
| **taksa-benthos-umh** | Industrial stream processing (OPC UA, Modbus, S7, Sparkplug B plugins) | Go (Benthos/Redpanda Connect) |
| **taksa-edge-umh** | Single-container edge IoT gateway with FSM lifecycle | Go, Redpanda, S6 process supervisor |
| **taksa-deployments** | Docker Compose and Kubernetes manifests | HAProxy, Ory Kratos/Oathkeeper, NATS, Grafana |

### Key Patterns

- **Kratos v2 layered architecture** (traceability, platform services): Proto → Service → Biz → Data → Storage. Code generation via `protoc`, `kratos`, and `wire`.
- **FSM-based lifecycle** (edge-umh): Each component (Benthos, Redpanda, S6) has `machine.go` (states), `actions.go` (operations), `reconcile.go` (control loop). Single-threaded, idempotent.
- **Async action pattern** (device-management): Client sends action → gets `action_id` → device polls for queued actions → returns results → client polls for completion.
- **UNS topic naming** (benthos-umh): Enforces underscore-based data contract naming convention for Unified Namespace topics.

### Platform Stack (via taksa-deployments)

HAProxy (443) → Ory Oathkeeper (authz) → Services. Identity via Ory Kratos. Messaging via NATS/JetStream. Time-series in TimescaleDB. Config in `taksa.env`.
