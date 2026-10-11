#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
. /etc/os-release
[[ $ID == ubuntu && ( $VERSION_ID == 24.04 || $VERSION_ID == 22.04 || $VERSION_ID == 26.04 ) ]] || { echo 'Ubuntu 22.04/24.04/26.04 required.' >&2; exit 1; }
apt-get update
apt-get install -y ca-certificates curl git jq python3 nodejs npm gh
# Dedicated coding identity. Deliberately not a member of the docker group.
id autovps >/dev/null 2>&1 || useradd --create-home --shell /bin/bash autovps
install -d -m 0755 /opt/autovps
if ! command -v codex >/dev/null; then npm install -g @openai/codex; fi
codex --version
printf '%s\n' 'Bootstrap complete. Next: register a GitHub runner as autovps (README).' 'Authenticate Codex as autovps using device login OR secure API credentials.' 'Docker/deployment host setup is separate; existing containers were not changed.'
