#!/home/agent/.nix-profile/bin/bash
set -euo pipefail

source "$HOME/.nix-profile/etc/profile.d/nix.sh"
source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

if [ "${1:-serve}" = "serve" ]; then
    host="${OPENCODE_HOST:-127.0.0.1}"
    port="${OPENCODE_PORT:-4096}"

    exec opencode serve \
        --hostname "$host" \
        --port "$port"
fi

exec "$@"