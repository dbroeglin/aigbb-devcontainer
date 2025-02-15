#!/usr/bin/env bash
set -euo pipefail
[[ ${DEBUG-} =~ ^1|yes|true$ ]] && set -o xtrace

# Update the package list and upgrade all packages
sudo apt update
sudo apt upgrade -y

# Install UV and sync the configuration (installs required python packages)
curl -LsSf https://astral.sh/uv/install.sh | sh
uv sync

# Install Staship prompt
curl -sS https://starship.rs/install.sh | sh -s -- -y
echo 'eval "$(starship init bash)"' >> ~/.bashrc
source ~/.bashrc



