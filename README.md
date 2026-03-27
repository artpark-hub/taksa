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
- `build/`: Local, isolated Go toolchain and build artifacts (generated via `make setup`).
- `scripts/`: Build and utility scripts.
- `services/`: Core service definitions and shared logic.
- `Makefile`: Centralized orchestration for the entire stack.
- `VERSION`: Defines the target branch, version, and Docker registry/label for all components.

## Submodule Repositories

| Repository | Path | Description |
| :--- | :--- | :--- |
| [taksa-app-traceability](repos/taksa-app-traceability) | `repos/taksa-app-traceability` | MES Traceability application. |
| [taksa-benthos-umh](repos/taksa-benthos-umh) | `repos/taksa-benthos-umh` | Streaming engine and data flow components. |
| [taksa-deployments](repos/taksa-deployments) | `repos/taksa-deployments` | Deployment scripts for Platform and Edge. |
| [taksa-edge-umh](repos/taksa-edge-umh) | `repos/taksa-edge-umh` | UMH edge solution for factory data ingestion. |
| [taksa-platform-dm](repos/taksa-platform-dm) | `repos/taksa-platform-dm` | Platform Data Management service. |
| [taksa-platform-services](repos/taksa-platform-services) | `repos/taksa-platform-services` | Core platform services. |
| [taksa-ui](repos/taksa-ui) | `repos/taksa-ui` | User Interface and dashboard. |

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

### 2. Initialize Submodules & Hooks

This command initializes all submodules, configures local Git settings (to prevent unpushed submodule commits), and installs `lefthook` for pre-push validation.

```bash
make init-repo
```

### 3. Setup Development Environment

Download a local Go toolchain and configure the build environment (isolated to the `build/` directory):

```bash
make setup
```
The environment variables (`GOROOT`, `GOPATH`, `PATH`) are now handled directly within the `Makefile`, eliminating the need to source external `.env` files.

### 4. Build the Stack

**Build All Components:**
```bash
make build
```

**Build Individual Submodules:**
You can build specific parts of the stack to save time:
- `make build-ui`
- `make build-traceability`
- `make build-services`
- `make build-edge`
- `make build-dm`
- `make build-benthos`

### 5. Running Commands in Build Environment

Use the `shellcmd` target to run arbitrary commands (like `go install` or `go version`) using the internal Taksa toolchain instead of your system's global environment:

```bash
make shellcmd go version
make shellcmd go install github.com/some/tool@latest
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
- `make clean`: Prune unused Docker images and volumes.
- `make help`: List all available targets with descriptions.

## Versioning & Docker Registry

All Docker images are tagged using values defined in the `VERSION` file:
- `DOCKER_REGISTRY`: The destination registry (default: `taksa-registry.local`).
- `DOCKER_LABEL`: The image tag (default: `dev`).

Modify these in the `VERSION` file to change the tagging strategy across the entire project.
