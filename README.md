# Taksa Meta Repository

This is the meta repository for the Taksa project, managing all related services and components as git submodules.

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

## Getting Started

To clone this repository along with all submodules, run:

```bash
git clone --recursive git@github.com:artpark-hub/taksa.git
```

Alternatively, if you have already cloned the repo, run the installation script:

```bash
./install.sh
```
