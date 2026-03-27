#!/usr/bin/env bash

set -euo pipefail

# ---------- helpers ----------
log() {
  echo -e "\n[INFO] $1"
}

err() {
  echo -e "\n[ERROR] $1" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || err "Required command '$1' not found"
}

# ---------- sanity ----------
require_cmd sudo
require_cmd curl
require_cmd wget

# ---------- system update ----------
log "Updating system packages"
sudo apt update || err "apt update failed"
sudo apt upgrade -y || err "apt upgrade failed"

# ---------- base dependencies ----------
log "Installing system dependencies"
sudo apt install -y \
  build-essential \
  ca-certificates \
  curl \
  git \
  unzip \
  make \
  pkg-config \
  software-properties-common \
  net-tools \
  iputils-ping \
  htop \
  tree \
  jq || err "System dependency installation failed"

# ---------- Go installation ----------
GO_VERSION="1.24.6"
GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_TARBALL}"

log "Downloading Go ${GO_VERSION}"
wget -q "${GO_URL}" || err "Failed to download Go tarball"

log "Installing Go to /usr/local"
sudo rm -rf /usr/local/go || err "Failed to remove existing Go installation"
sudo tar -C /usr/local -xzf "${GO_TARBALL}" || err "Failed to extract Go tarball"
rm -f "${GO_TARBALL}"

# ---------- environment setup ----------
BASHRC="$HOME/.bashrc"
GO_ENV_LINE='export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin'

log "Configuring Go environment in ~/.bashrc"
if ! grep -q "/usr/local/go/bin" "$BASHRC"; then
  echo "$GO_ENV_LINE" >> "$BASHRC"
else
  log "Go PATH already present in ~/.bashrc"
fi

# shellcheck disable=SC1090
source "$BASHRC" || err "Failed to source ~/.bashrc"

# ---------- validation ----------
log "Validating Go installation"
require_cmd go

GO_INSTALLED_VERSION=$(go version | awk '{print $3}')
EXPECTED_VERSION="go${GO_VERSION}"

if [[ "$GO_INSTALLED_VERSION" != "$EXPECTED_VERSION" ]]; then
  err "Go version mismatch. Expected ${EXPECTED_VERSION}, got ${GO_INSTALLED_VERSION}"
fi

log "Go version OK: $(go version)"

# ---------- Kratos ----------
log "Installing Kratos CLI"
go install github.com/go-kratos/kratos/cmd/kratos/v2@latest || err "Kratos install failed"

require_cmd kratos
log "Kratos installed: $(kratos version)"

# ---------- Protobuf ----------
log "Installing protobuf compiler"
sudo apt install -y protobuf-compiler || err "protoc installation failed"

require_cmd protoc
log "protoc installed: $(protoc --version)"

# ---------- Protoc validator ----------
log "Installing protoc-gen-validate"
go install github.com/envoyproxy/protoc-gen-validate@latest || err "protoc-gen-validate install failed"

require_cmd protoc-gen-validate
log "protoc-gen-validate installed successfully"

# ---------- done ----------
log "Build environment setup completed successfully 🎉"
