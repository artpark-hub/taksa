# Taksa Factory OS

**Taksa** is an open source factory OS designed to build dashboards and features for the modern manufacturing environment. It serves as a comprehensive **Digital Foundation for manufacturing factory**, offering:

- IoT data capture from PLCs / machines
- MES / MES-lite for production & traceability
- Real-time PQCDSM dashboards
- OEE monitoring & downtime analytics
- Energy monitoring
- Role-based reporting (Plant Head to Operator)

This is the meta repository for the Taksa project, managing all related services and components as Git submodules.

## Submodule Repositories

| Repository | Description |
| :--- | :--- |
| [taksa-app-traceability](taksa-app-traceability) | MES Traceability application for tracking manufacturing units throughout their lifecycle. |
| [taksa-benthos-umh](taksa-benthos-umh) | High-throughput streaming engine and data flow components based on Benthos. |
| [taksa-build](taksa-build) | Open source Factory OS build system. |
| [taksa-deployments](taksa-deployments) | Deployment scripts for Taksa platform and edge components. |
| [taksa-edge-umh](taksa-edge-umh) | United Manufacturing Hub edge solution for ingesting and contextualizing factory data. |
| [taksa-kratos-layout](taksa-kratos-layout) | Project template based on the Kratos Go framework. |
| [taksa-platform-dm](taksa-platform-dm) | Platform Data Management service. |
| [taksa-platform-services](taksa-platform-services) | Core platform services for the Taksa ecosystem. |
| [taksa-ui](taksa-ui) | User Interface files and container for the Taksa platform. |

## Prerequisites

Ensure you have the following installed on your system:
- Git
- Docker & Docker Compose
- Make

## Getting Started: Bootstrap, Build, and Orchestrate

Follow these steps to set up the Taksa stack on your local environment.

### 1. Clone the Repository

Clone the meta repository directly:

```bash
git clone git@github.com:artpark-hub/taksa.git
cd taksa
```

### 2. Bootstrap Submodules

Initialize and update all submodules associated with the Taksa ecosystem by running the bootstrap script:

```bash
./bootstrap.sh
```

This ensures that all connected repositories (UI, backend services, deployments, etc.) are pulled to their currently specified branches/commits.

### 3. Build the Stack

We provide a dedicated `taksa-build` repository to manage all build steps.

```bash
cd taksa-build
```

You can view all available build targets by running:
```bash
make help
```

To build all Taksa components (or specific ones like the UI), use the Make targets:
```bash
# To build a specific service, e.g., the UI:
make build-ui

# To build all repositories, run:
make build-all

# Return to root directory once finished
cd ..
```

### 4. Deploy and Orchestrate

Orchestration is handled via Docker Compose in the `taksa-deployments` repository. 

Navigate to the platform docker-compose directory:

```bash
cd taksa-deployments/platform/docker-compose
```

**Initialize the Setup:**

The `make init` command will set up the required directories (for databases, Grafana, NATS, etc.) and generate local SSL certificates (e.g., for `localcontroller.taksa-os.manufacturing`). It might ask for user confirmation.

```bash
make init
```

**Start the Platform:**

Spin up the entire stack in the background including HAProxy API Gateway, PostgreSQL, TimescaleDB, Kratos, Oathkeeper, Grafana, NATS, and the UI:

```bash
make up
```

You can verify that your containers are running via:
```bash
docker ps
```
