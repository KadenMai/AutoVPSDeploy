#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Run: sudo bash install.sh' >&2; exit 1; }
. /etc/os-release
[[ $ID == ubuntu && ( $VERSION_ID == 22.04 || $VERSION_ID == 24.04 ) ]] || { echo 'Ubuntu 22.04/24.04 required.' >&2; exit 1; }
command -v curl >/dev/null || { echo 'Install curl first: apt-get update && apt-get install -y curl' >&2; exit 1; }
# Pin the downloaded implementation; do not execute moving branch contents.
release_commit=059f7312e1c64aa908d392e87bc83f1b10dd03bc
base="https://raw.githubusercontent.com/KadenMai/AutoVPSDeploy/$release_commit"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
for file in bootstrap.sh prepare-project.sh run-task.py deploy.sh; do
  curl --proto '=https' --tlsv1.2 -fsSL --retry 3 "$base/scripts/$file" -o "$tmp/$file"
done
curl --proto '=https' --tlsv1.2 -fsSL --retry 3 "$base/README.md" -o "$tmp/README.md"
bash -n "$tmp/bootstrap.sh" "$tmp/prepare-project.sh" "$tmp/deploy.sh"
python3 -c 'import ast,sys; ast.parse(open(sys.argv[1]).read())' "$tmp/run-task.py"
bash "$tmp/bootstrap.sh"
install -d -o root -g root -m 0755 /opt/autovps/scripts
for file in bootstrap.sh prepare-project.sh run-task.py deploy.sh; do
  install -o root -g root -m 0755 "$tmp/$file" "/opt/autovps/scripts/$file"
done
install -o root -g root -m 0644 "$tmp/README.md" /opt/autovps/README.md
printf '%s\n' "$release_commit" > /opt/autovps/installed-commit
printf '%s\n' 'Installed AutoVPSDeploy scripts in /opt/autovps.' 'Next: sudo -iu autovps codex login --device-auth' 'GitHub runner registration and app deployment configuration are still required.' 'No Docker containers, SSH settings or firewall rules were changed.'
