# Taksa Factory OS

**Taksa** is an open-source factory OS designed to build dashboards and features for the modern manufacturing environment. It serves as a comprehensive **Digital Foundation for the manufacturing factory**, offering:

- IoT data capture from PLCs / machines
- MES / MES-lite for production & traceability
- Real-time PQCDSM dashboards
- OEE monitoring & downtime analytics
- Energy monitoring
- Role-based reporting (Plant Head to Operator)

This is the meta-repository for the Taksa project, managing all related services and components as Git submodules.

## Project Structure

- `repos/`: Contains all Taksa submodules.
- `_build/`: Local, isolated Go toolchain and build artifacts (generated via `make init`).
- `scripts/`: Build and utility scripts.
- `Makefile`: Centralized orchestration for the entire stack.
- `VERSION`: Defines the target branch, version, and Docker registry/label for all components.

## Submodule Repositories

| Repository | Path | Description |
| :--- | :--- | :--- |
| [taksa-app-traceability](repos/taksa-app-traceability) | `repos/taksa-app-traceability` | MES Traceability application. |
| [taksa-benthos-umh](repos/taksa-benthos-umh) | `repos/taksa-benthos-umh` | Benthos(redpanda connect) based data transformation edge layer. |
| [taksa-deployments](repos/taksa-deployments) | `repos/taksa-deployments` | Deployment scripts for Platform and Edge. |
| [taksa-edge-umh](repos/taksa-edge-umh) | `repos/taksa-edge-umh` | UMH edge solution for factory data ingestion. |
| [taksa-platform](repos/taksa-platform) | `repos/taksa-platform` | Core platform monorepo (user-management, device-management, ui-service). |

## Prerequisites

Ensure you have the following installed on your system:
- Git
- Docker & Docker Compose (v2 recommended)
- Make
- Curl (for environment setup)

## Getting Started

### 1. Clone the Repository

```bash
git clone git@github.com:artpark-hub/taksa.git
cd taksa
```

### 2. Initialize & Sync Submodules

This command initializes and updates all submodules to the branch specified in the `VERSION` file.

```bash
make repo-sync
```

### 3. Setup Development Environment

Download a local Go toolchain and configure the build environment (isolated to the `_build/` directory):

```bash
make init
```
The environment variables (`GOROOT`, `GOPATH`, `PATH`) are handled directly within the `Makefile`, ensuring an isolated build environment.

### 4. Build the Stack

**Build All Components:**
```bash
make build-all
```

**Build Individual Components:**
- `make build-platform`: Build core platform services (DM, User, UI).
- `make build-traceability`: Build MES traceability service.
- `make build-edge`: Build edge IoT gateway.
- `make build-benthos`: Build stream processing layer.

### 5. Running Commands in Build Environment

Use the `shellcmd` target to run arbitrary commands (like `go version`) using the internal Taksa toolchain:

```bash
make shellcmd go version
```

### 6. Deploy the Platform

**Initialize Platform Configuration:**
Sets up data directories and generates local SSL certificates.
```bash
make platform-init
```

**Start the Platform:**
Spins up the entire stack (PostgreSQL, TimescaleDB, Grafana, NATS, UI, etc.) in the background.
```bash
make platform-up
```

## Management Targets

- `make platform-down`: Stop and remove the platform stack.
- `make platform-logs`: Follow platform container logs.
- `make clean`: Prune unused Docker images and volumes.
- `make help`: List all available targets with descriptions.

## Versioning & Docker Registry

All Docker images are tagged using values defined in the `VERSION` file:
- `BRANCH`: The target branch for submodules (e.g., `release/0.0.x`).
- `DOCKER_REGISTRY`: The destination registry (default: `registry.taksa.org`).
- `DOCKER_LABEL`: The image tag (default: `dev`).

Modify these in the `VERSION` file to change the strategy across the entire project.
