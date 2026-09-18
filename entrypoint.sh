#!/bin/bash
set -euo pipefail

source "$HOME/.nix-profile/etc/profile.d/nix.sh"
source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

if [[ "${HM_UPDATE_ON_START:-1}" == "1" ]]; then
    echo "Updating Nix channels..."
    nix-channel --update
    echo "Applying Home Manager configuration..."
    home-manager switch -b backup
fi

if [ "${1:-serve}" = "serve" ]; then
    host="${OPENCODE_HOST:-0.0.0.0}"
    port="${OPENCODE_PORT:-4096}"

    exec opencode serve \
        --hostname "$host" \
        --port "$port" \
        --print-logs
fi

exec "$@"