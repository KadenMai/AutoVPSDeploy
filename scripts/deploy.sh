#!/usr/bin/env bash
# Run on a deployment host; compose config/secrets are provisioned by an operator.
set -euo pipefail
project=${1:?project required}; environment=${2:?staging or production required}; image=${3:?immutable image digest required}
[[ $project =~ ^[a-z][a-z0-9-]{0,40}$ ]] || exit 2
[[ $environment == staging || $environment == production ]] || exit 2
[[ $image =~ ^[a-zA-Z0-9./:_-]+@sha256:[a-f0-9]{64}$ ]] || { echo 'Use an immutable image digest.' >&2; exit 2; }
root="/opt/families/$project/$environment"
cd "$root"
exec 9>deploy.lock
flock -w 300 9
[[ -f compose.yml && -f runtime.env ]] || { echo 'Missing compose.yml or runtime.env' >&2; exit 1; }
previous=$(cat current-image 2>/dev/null || true)
export APP_IMAGE="$image"
docker compose --env-file runtime.env -p "$project-$environment" -f compose.yml pull
if ! docker compose --env-file runtime.env -p "$project-$environment" -f compose.yml up -d --wait --wait-timeout 120; then
  if [[ -n $previous ]]; then
    export APP_IMAGE="$previous"
    docker compose --env-file runtime.env -p "$project-$environment" -f compose.yml up -d --wait --wait-timeout 120
  fi
  exit 1
fi
printf '%s\n' "$image" > current-image.tmp
mv current-image.tmp current-image
